using UnityEngine;
using Cysharp.Threading.Tasks;
using System.Threading;
using System.Collections.Generic;
using System.Diagnostics;
using System;
using Random = UnityEngine.Random;

public class CommandoBaseState : S_EnemyState
{
    protected CommandoController mController;

    public CommandoBaseState(CommandoController controller) : base(controller)
    {
        mController = controller as CommandoController;
    }

    // プレイヤー方向に向かせる
    protected void FaceTarget()
    {
        if (mController.target == null) return;
        Vector2 toPlayer = mController.target.position - mController.transform.position;
        mController.ForceFacing(toPlayer);
    }
}

public class CommandoIdleState : CommandoBaseState
{
    public CommandoIdleState(CommandoController core) : base(core) { }

    public override void Enter()
    {
        mController.Rb.linearVelocity = Vector2.zero;
        mController.ShouldAutoFacing = true;
    }

    public override void Update()
    {
        if (mController.target == null) return;

        // プレイヤーを発見したら、まずは様子見で間合いを測る
        mController.ChangeState(new CommandoObserveState(mController));
    }
}

// --- Observe State (複合型の間合い管理) ---
public class CommandoObserveState : CommandoBaseState
{
    private float _observeTimer;
    private int _tactics;  // 旋回方向（0=反時計回り, 1=時計回り）を保持するフラグ

    public CommandoObserveState(CommandoController core) : base(core) { }

    public override void Enter()
    {
        _observeTimer = Random.Range(mController.observeMinTime, mController.observeMaxTime);
        _tactics = Random.Range(0, 2);
        mController.ShouldAutoFacing = false;
    }

    public override void Update()
    {
        FaceTarget();
        if (mController.target == null) return;

        float dist = Vector2.Distance(mController.transform.position, mController.target.position);
        _observeTimer -= Time.deltaTime;

        // 必殺技チェック
        if (mController.CanUseUltimate())
        {
            mController.Status.ConsumeSpecialGauge();
            mController.ChangeState(new CommandoUltimateState(mController));
            return;
        }

        // 近づかれすぎた場合は即座に近接へ
        if (dist <= mController.meleeRange)
        {
            mController.SwitchWeaponSprite(true);
            mController.ChangeState(new CommandoMeleeChaseState(mController));
            return;
        }

        // --- 特殊攻撃ロジック ---
        // 各フレーム一定確率で特殊攻撃が発生するか、タイマー終了時に発生する
        bool timeUp = _observeTimer <= 0f;
        if (timeUp || Random.value < mController.specialAttackChancePerSecond * Time.deltaTime)
        {
            // Phase2: グレネード/閃光手榴弾投げ（クールダウンなし・確率で発動）
            if (mController.CurrentPhase >= 2 && Random.value < mController.phase2GrenadeChance)
            {
                mController.ChangeState(new CommandoGrenadeThrowState(mController));
                return;
            }

            List<int> skills = new List<int>();
            if (mController.CheckAbilityAvailable(0)) skills.Add(0);
            if (mController.CurrentPhase >= 2 && mController.CheckAbilityAvailable(1)) skills.Add(1);
            if (mController.CurrentPhase >= 3 && mController.CheckAbilityAvailable(2)) skills.Add(2);

            if (skills.Count > 0)
            {
                int skill = skills[Random.Range(0, skills.Count)];
                mController.UseAbility(skill);
                switch (skill)
                {
                    case 0: mController.ChangeState(new CommandoArtilleryState(mController)); return;
                    case 1: mController.ChangeState(new CommandoReloadBurstState(mController)); return;
                    case 2: mController.ChangeState(new CommandoCallReinforcementState(mController)); return;
                }
            }

        }

        // 様子見中にプレイヤーが離れすぎた場合、即座に遠距離攻撃
        // 射撃範囲の80%以上離れたら「逃げている」と判断して撃つ
        if (dist > mController.shootRange * 0.8f)
        {
            mController.SwitchWeaponSprite(false);
            mController.ChangeState(new CommandoRangedState(mController));
            return;
        }

        // 長い時間（タイマー終了まで）プレイヤーが近づいてこなかった場合
        if (timeUp)
        {
            // 近接範囲の少し外側より遠いなら、確率判定を無視して確定で遠距離攻撃
            if (dist > mController.meleeRange * 1.5f)
            {
                mController.SwitchWeaponSprite(false);
                mController.ChangeState(new CommandoRangedState(mController));
            }
            else
            {
                // 近接範囲のすぐ外にいるなら、一気に距離を詰めて近接攻撃
                mController.SwitchWeaponSprite(true);
                mController.ChangeState(new CommandoMeleeChaseState(mController));
            }
        }
    }

    public override void FixedUpdate()
    {
        if (mController.target == null) return;
        Vector2 toPlayer = mController.target.position - mController.transform.position;
        float dist = toPlayer.magnitude;
        Vector2 dir = toPlayer.normalized;
        Vector2 desiredDir = Vector2.zero;
        float currentSpeed = mController.Status.Data.moveSpeed;

        float keepDistMin = mController.meleeRange * 2.0f;
        float keepDistMax = mController.shootRange * 0.8f;

        // プレイヤーが近づいてきたら後退して一定距離を保つ
        if (dist < keepDistMin)
        {
            desiredDir = -dir;
            currentSpeed *= 1.5f;
        }
        // 直進(dir)と横移動(circleDir)を合成し、斜め前に進みながらジリジリと距離を詰める
        else if (dist > keepDistMax)
        {
            // _tactics(0 or 1)によって時計回り/反時計回りを切り替え、動きの単調さを消す
            Vector2 circleDir = (_tactics == 0) ? new Vector2(-dir.y, dir.x) : new Vector2(dir.y, -dir.x);
            desiredDir = (dir + circleDir).normalized;
            currentSpeed *= 0.8f;
        }
        // 近づきも遠ざかりもせず、プレイヤーの周囲を円を描くように純粋に旋回する
        else
        {
            desiredDir = (_tactics == 0) ? new Vector2(-dir.y, dir.x) : new Vector2(dir.y, -dir.x);
            currentSpeed *= 0.6f;
        }

        mController.Rb.linearVelocity = mController.GetAvoidanceVelocity(desiredDir, currentSpeed);
    }
}

public class CommandoMeleeChaseState : CommandoBaseState
{
    public CommandoMeleeChaseState(CommandoController core) : base(core) { }

    public float _changeWeaponRatio;

    public override void Enter()
    {
        mController.SwitchWeaponSprite(true);
        mController.ShouldAutoFacing = false;
        _changeWeaponRatio = mController.meleeToRangedRatio;
    }

    public override void FixedUpdate()
    {
        if (mController.target == null) return;
        Vector2 dir = (mController.target.position - mController.transform.position).normalized;
        mController.Rb.linearVelocity = dir * mController.meleeChaseSpeed;
    }

    public override void Update()
    {
        if (mController.target == null) { mController.ChangeState(new CommandoIdleState(mController)); return; }

        float dist = Vector2.Distance(mController.transform.position, mController.target.position);
        // 攻撃範囲に入ったら攻撃
        bool canMelee = dist <= mController.meleeRange;
        if (canMelee)
        {
            mController.ChangeState(new CommandoMeleeAttackState(mController, 1));
            return;
        }

        // 射程範囲より遠いなら武器変更確率増加
        if (dist < mController.shootRange)
        {
            _changeWeaponRatio = mController.meleeToRangedRatio;
        }
        else
        {
            _changeWeaponRatio = mController.meleeToRangedRatio * 2;
        }

        // 武器変更チェック
        if (Random.value < _changeWeaponRatio * Time.deltaTime)
        {
            mController.ChangeState(new CommandoRangedState(mController));
        }
    }
}

// ---------------------------------------------------------
// 通常攻撃 (Normal Attacks)
// ---------------------------------------------------------

// N1 Melee: 高速接近して攻撃
public class CommandoMeleeAttackState : CommandoBaseState
{
    private int _comboIndex;  //現在のコンボ数
    private float _timer;
    private float _attackDuration = 0.4f; // 攻撃動作の時間
    private float _hitboxStart = 0.2f;  //攻撃判定が出る時間
    private float _hitboxEnd = 0.25f;  //攻撃判定が終わる時間
    private bool _nextComboQueued = false;  //コンボフラグ

    public CommandoMeleeAttackState(CommandoController core, int comboIndex) : base(core)
    {
        _comboIndex = comboIndex;
    }

    public override void Enter()
    {
        mController.Rb.linearVelocity = Vector2.zero; // その場で止まる
        _timer = 0f;
        Vector2 faceDir = Vector2.down;
        if (mController.target != null)
            faceDir = (mController.target.position - mController.transform.position).normalized;
        mController.ForceFacing(faceDir);

        // 武器画像を強制的に近接に (Idleから直接遷移した場合などのため)
        mController.SwitchWeaponSprite(true);

        // アニメーション再生（Triggerを使うか、Integerで管理するか）
        mController.Anim.SetInteger("comboIndex", _comboIndex);
        mController.Anim.SetTrigger("Attack");

        // 効果音再生
        if (mController.meleeAttackSound != null)
        {
            AudioManager.Instance.Pitch(Random.Range(0.9f, 1.1f));
            AudioManager.Instance.PlaySE(mController.meleeAttackSound);
        }

        // コンボ予約フラグは必ずリセット
        _nextComboQueued = false;
    }

    public override void Update()
    {
        if (mController.target == null) return;
        float dist = Vector2.Distance(mController.transform.position, mController.target.position);

        _timer += Time.deltaTime;

        if (_timer >= _hitboxStart && _timer < _hitboxEnd)
        {
            //攻撃判定ON
            int damage = mController.Status.AdjustedAttackPower + (_comboIndex * 2);
            mController.SetWeaponActive(true, damage);
        }
        else
        {
            mController.SetWeaponActive(false, 0);
        }

        //コンボ確定判定
        if (!_nextComboQueued && _timer > _attackDuration * 0.5f && dist <= mController.meleeRange)
        {
            _nextComboQueued = true;
        }

        // 一定時間経過したら攻撃終了
        if (_timer >= _attackDuration)
        {
            if (_nextComboQueued && _comboIndex < 2)  //最大2コンボ
            {
                mController.ChangeState(new CommandoMeleeAttackState(mController, _comboIndex + 1));
            }
            else
            {
                mController.ChangeState(new CommandoIdleState(mController));
            }
        }
    }

    public override void Exit()
    {
        mController.SetWeaponActive(false, 0); // 当たり判定無効化
        mController.Anim.SetInteger("comboIndex", 0); // コンボ数リセット
    }
}

public class CommandoRangedState : CommandoBaseState
{
    private enum SubState { Shooting, Interval, Reloading }
    private SubState _subState;

    private float _timer;
    private float _lastShotTime;
    private int _shotCount;    // 今回のバーストで撃つ弾数
    private int _maxShotCount = 3; // バーストの最大弾数（仮定）
    private int _shotsFiredInBurst; // バースト中に撃った数
    private int _burstCycles = 0;   // バーストした回数
    private int _maxBurstCycles = 2; // 何回バーストしたらIdleに戻るか

    private float _weaponChangeChance;  // 近接への変更確率

    public CommandoRangedState(CommandoController core) : base(core) { }

    public override void Enter()
    {
        mController.Rb.linearVelocity = Vector2.zero;
        _timer = 0f;

        // 初回弾数チェック（もし0なら補充）
        if (mController.CurrentAmmo <= 0)
        {
            mController.CurrentAmmo = mController.CurrentMaxAmmo > 0 ? mController.CurrentMaxAmmo : 5; // デフォルト5
        }

        // 武器画像切り替え (射撃)
        mController.SwitchWeaponSprite(false);

        _burstCycles = 0;
        _maxBurstCycles = Random.Range(1, 4); // 1~3回バーストしたら様子見

        SetupBurst();
    }

    private void SetupBurst()
    {
        // バースト回数制限チェック
        if (_burstCycles >= _maxBurstCycles)
        {
            mController.ChangeState(new CommandoIdleState(mController));
            return;
        }

        // バースト数を決定
        _maxShotCount = mController.CurrentBurstCount; // 固定値またはInspector等から取得
        _shotCount = Random.Range(1, _maxShotCount + 1);

        // 残弾チェック
        if (_shotCount > mController.CurrentAmmo)
        {
            _shotCount = mController.CurrentAmmo;
        }

        // 状態決定
        if (mController.CurrentAmmo <= 0)
        {
            StartReload();
        }
        else
        {
            _subState = SubState.Shooting;
            _shotsFiredInBurst = 0;
            _lastShotTime = Time.time - mController.CurrentFireRate; // 即時発射可能にする
        }
    }

    private void StartReload()
    {
        _subState = SubState.Reloading;
        _timer = 0f;
    }

    public override void Update()
    {
        if (mController.target == null)
        {
            mController.ChangeState(new CommandoIdleState(mController));
            return;
        }

        float dist = Vector2.Distance(mController.transform.position, mController.target.position);

        // 強制近接スイッチ (距離が近すぎる場合)
        if (dist <= mController.meleeRange)
        {
            // 近すぎるので即近接攻撃へ
            mController.ChangeState(new CommandoMeleeAttackState(mController, 1));
            return;
        }

        // 移動ロジック (リロード中以外は常に動く)
        if (_subState != SubState.Reloading)
        {
            Vector2 dir = (mController.target.position - mController.transform.position).normalized;

            // ヒステリシスを持たせてジタバタ防止
            if (dist > mController.shootRange + 0.5f)
            {
                // 遠すぎる -> 近づく
                mController.Rb.linearVelocity = dir * mController.rangedApproachSpeed;
                _weaponChangeChance = mController.rangedToMeleeRatio * 0.5f;
            }
            else if (dist < mController.shootRange - 1.5f) // 少し余裕を持って下がる
            {
                // 近すぎる -> 離れる
                mController.Rb.linearVelocity = -dir * mController.rangedBackStepSpeed;
                _weaponChangeChance = mController.rangedToMeleeRatio * 2;
            }
            else
            {
                // ちょうどいい -> 停止
                mController.Rb.linearVelocity = Vector2.zero;
                _weaponChangeChance = mController.rangedToMeleeRatio;
            }

            // 銃の向き
            mController.gunPivot.transform.localRotation = Quaternion.Euler(dir.x, dir.y, 0); // この行は下のrotation上書きで意味なくなるが残しておく
        }
        else
        {
            // リロード中は停止
            mController.Rb.linearVelocity = Vector2.zero;
        }

        // 武器変更チェック (頻度調整)
        if (Random.value < _weaponChangeChance * Time.deltaTime)
        {
            mController.ChangeState(new CommandoMeleeChaseState(mController));
        }

        // 銃の向き合わせ
        if (mController.target != null && mController.gunPivot != null)
        {
            Vector2 dir = (mController.target.position - mController.transform.position).normalized;

            float angle = Mathf.Atan2(dir.y, dir.x) * Mathf.Rad2Deg;
            mController.gunPivot.rotation = Quaternion.Euler(0, 0, angle + 90f);
        }

        // 2. 状態別更新
        switch (_subState)
        {
            case SubState.Shooting:
                UpdateShooting();
                break;
            case SubState.Interval:
                UpdateInterval();
                break;
            case SubState.Reloading:
                // リロードステートへ委譲
                mController.ChangeState(new CommandoReloadState(mController));
                break;
        }
    }

    private void UpdateShooting()
    {
        if (Time.time - _lastShotTime >= mController.CurrentFireRate)
        {
            Fire();
            _lastShotTime = Time.time;
            _shotsFiredInBurst++;
            mController.CurrentAmmo--;

            // バースト終了判定
            if (_shotsFiredInBurst >= _shotCount)
            {
                _subState = SubState.Interval;
                _timer = 0f; // Interval用タイマーリセット
                _burstCycles++; // バースト回数カウント
            }

            // 弾切れ判定（バースト途中でも弾切れしたらリロード）
            if (mController.CurrentAmmo <= 0)
            {
                StartReload();
            }
        }
    }

    private void UpdateInterval()
    {
        _timer += Time.deltaTime;
        if (_timer >= mController.firedInterval)
        {
            SetupBurst(); // 次のバーストへ
        }
    }

    private void Fire()
    {
        if (mController.bulletPrefab != null)
        {
            Vector2 dir = (mController.target.position - mController.transform.position).normalized;

            // BulletPatternを使用して射撃
            BulletPattern.FireLine(mController.bulletPrefab, mController.transform.position, 1, dir, mController.bulletSpeed, 0, 10, (obj) =>
            {
                var bullet = obj.GetComponent<BulletBase>();
                if (bullet != null)
                {
                    bullet.usePenetration = true;
                    bullet.ApplyPhysicsSetting();
                }
            });

            // 射撃音
            if (mController.gunShootSound != null)
            {
                AudioManager.Instance.Pitch(Random.Range(0.9f, 1.1f));
                AudioManager.Instance.PlaySE(mController.gunShootSound);
            }
        }
    }
}

public class CommandoReloadState : CommandoBaseState
{
    private float _timer;
    public CommandoReloadState(CommandoController core) : base(core) { }
    public override void Enter()
    {
        _timer = 0f;
        mController.Rb.linearVelocity = Vector2.zero;
        // 武器画像切り替え (念のため射撃用)
        mController.SwitchWeaponSprite(false);
    }
    public override void Update()
    {
        _timer += Time.deltaTime;
        if (_timer >= mController.reloadTime)
        {
            mController.CurrentAmmo = mController.CurrentMaxAmmo;
            if (mController.reloadSound != null) AudioManager.Instance.PlaySE(mController.reloadSound, 0.7f);
            mController.ChangeState(new CommandoIdleState(mController));
        }
    }
}

// ---------------------------------------------------------
// 特殊攻撃 (Special Attacks)
// ---------------------------------------------------------

// Sp1: 砲撃 (Artillery)
public class CommandoArtilleryState : CommandoBaseState
{
    private CancellationTokenSource _linkedCts;
    public CommandoArtilleryState(CommandoController core) : base(core) { }

    public override void Enter()
    {
        // 武器画像切り替え (射撃)
        mController.SwitchWeaponSprite(false);
        mController.Rb.linearVelocity = Vector2.zero;
        ArtillerySequence().Forget();
    }

    private async UniTaskVoid ArtillerySequence()
    {
        var token = mController.GetCancellationTokenOnDestroy();

        // 音声・演出
        if (mController.artilleryVoice != null) AudioManager.Instance.PlaySE(mController.artilleryVoice, 1.0f);
        if (mController.jetNoise != null) AudioManager.Instance.PlaySE(mController.jetNoise, 1.0f);

        await UniTask.Delay(TimeSpan.FromSeconds(1.0f), cancellationToken: token); // 要請待ち

        // マーカー生成ループ
        for (int i = 0; i < mController.BombCount; i++)
        {
            Vector3 pos = Camera.main.ScreenToWorldPoint(
                    new Vector3(Random.Range(Screen.width / 4, Screen.width - Screen.width / 4), Random.Range(0, Screen.height), Camera.main.nearClipPlane));
            if (mController.artilleryMarkerPrefab != null)
            {
                // マーカー生成
                GameObject marker = ObjectPoolManager.Instance.GetObject(mController.artilleryMarkerPrefab, pos, Quaternion.identity);

                // 最初は当たり判定OFF
                var hitbox = marker.GetComponent<WeaponHitbox>();
                if (hitbox != null) hitbox.enabled = false;

                // 爆弾投下予約 (マーカー削除含む)
                SpawnBombAsync(marker, pos, mController.artilleryDelay, token).Forget();
            }
            await UniTask.Delay(TimeSpan.FromSeconds(mController.BombInterval), cancellationToken: token);
        }

        await UniTask.Delay(TimeSpan.FromSeconds(1.0f), cancellationToken: token);
        mController.ChangeState(new CommandoIdleState(mController));
    }

    private async UniTaskVoid SpawnBombAsync(GameObject marker, Vector2 pos, float delay, CancellationToken token)
    {
        // 警告表示
        EffectManager.Instance.PlayWarning(mController.warningEffect, pos, delay, mController.explosionRadius); // 半径は爆発処理と合わせる(2.5f)

        await UniTask.Delay(System.TimeSpan.FromSeconds(delay), cancellationToken: token);

        // ダメージ判定
        int damage = mController.Status.AdjustedAttackPower;

        EffectManager.Instance.PlayEffect(mController.explosionEffect, pos, mController.explosionRadius);

        Collider2D[] results = Physics2D.OverlapCircleAll(pos, mController.explosionRadius);

        for (int i = 0; i < results.Length; i++)
        {
            var c = results[i];
            if (c == null) continue;

            if (c.CompareTag("Player"))
            {
                var damageable = c.GetComponent<IDamageable>();
                if (damageable != null)
                {
                    damageable.TakeDamage(damage);
                }
            }
        }

        // マーカー削除
        if (marker != null) ObjectPoolManager.Instance.Release(marker);
    }
}

// Sp2: リロードバースト (Reload Burst)
public class CommandoReloadBurstState : CommandoBaseState
{
    public CommandoReloadBurstState(CommandoController core) : base(core) { }
    public override void Enter()
    {
        // 武器画像切り替え (射撃)
        mController.SwitchWeaponSprite(false);
        mController.Rb.linearVelocity = Vector2.zero;
        Sequence().Forget();
    }

    private async UniTaskVoid Sequence()
    {
        var token = mController.GetCancellationTokenOnDestroy();

        // 1. リロード演出
        if (mController.reloadSound != null) AudioManager.Instance.PlaySE(mController.reloadSound);
        await UniTask.Delay(System.TimeSpan.FromSeconds(mController.reloadTime), cancellationToken: token);

        // Sp2発動時専用の連射数
        int burstAmmo = mController.rifleMaxAmmo;

        // 2. 超連射ループ
        while (burstAmmo > 0)
        {
            if (mController.target != null)
            {
                Vector2 dir = (mController.target.position - mController.transform.position).normalized;
                mController.ForceFacing(dir);

                BulletPattern.FireLine(mController.bulletPrefab, mController.transform.position, 1, dir, mController.bulletSpeed, 0, mController.Status.AdjustedAttackPower, (obj) =>
                {
                    var bullet = obj.GetComponent<BulletBase>();
                    if (bullet != null)
                    {
                        bullet.usePenetration = true;
                        bullet.ApplyPhysicsSetting();
                    }
                });

                if (mController.rifleShootSound != null)
                    AudioManager.Instance.PlaySE(mController.rifleShootSound, 0.5f);
            }

            burstAmmo--;
            await UniTask.Delay(System.TimeSpan.FromSeconds(mController.burstFireRate), cancellationToken: token);
        }

        // 3. 再リロード（クールダウン）
        if (mController.reloadSound != null) AudioManager.Instance.PlaySE(mController.reloadSound);
        await UniTask.Delay(System.TimeSpan.FromSeconds(mController.reloadTime), cancellationToken: token);

        // 元のPhaseに応じた最大弾数にリセット
        mController.CurrentAmmo = mController.CurrentMaxAmmo;

        mController.ChangeState(new CommandoIdleState(mController));
    }
}

// Sp3: 増援要請 (Call Reinforcement)
public class CommandoCallReinforcementState : CommandoBaseState
{
    public CommandoCallReinforcementState(CommandoController core) : base(core) { }

    public override void Enter()
    {
        mController.SwitchWeaponSprite(false);
        mController.Rb.linearVelocity = Vector2.zero;
        Sequence().Forget();
    }

    private async UniTaskVoid Sequence()
    {
        var token = mController.GetCancellationTokenOnDestroy();

        if (mController.callReinforcementSound != null)
            AudioManager.Instance.PlaySE(mController.callReinforcementSound);

        // 音声が鳴り終わるまで待機
        await UniTask.Delay(TimeSpan.FromSeconds(2.0f), cancellationToken: token);

        if (mController.reinforcementPrefab != null)
        {
            for (int i = 0; i < mController.ReinforcementCount; i++)
            {
                Vector2 spawnPos;

                // スポーン地点リストが設定されている場合はそこからランダムに選ぶ
                if (mController.reinforcementSpawnPoints != null && mController.reinforcementSpawnPoints.Count > 0)
                {
                    int randomIndex = Random.Range(0, mController.reinforcementSpawnPoints.Count);
                    Transform spawnPoint = mController.reinforcementSpawnPoints[randomIndex];
                    spawnPos = spawnPoint != null ? (Vector2)spawnPoint.position : mController.transform.position;
                }
                else
                {
                    // フォールバック: 画面端のどこかにスポーン
                    bool spawnRight = Random.value > 0.5f;
                    float spawnX = spawnRight ? mController.maxScreenX + 1.5f : mController.minScreenX - 1.5f;
                    float spawnY = Random.Range(mController.minScreenY + 1f, mController.maxScreenY - 1f);
                    spawnPos = new Vector2(spawnX, spawnY);
                }

                ObjectPoolManager.Instance.GetObject(mController.reinforcementPrefab, spawnPos, Quaternion.identity);
                await UniTask.Delay(TimeSpan.FromSeconds(0.2f), cancellationToken: token); // 少し時間差でスポーン
            }
        }

        await UniTask.Delay(TimeSpan.FromSeconds(1.0f), cancellationToken: token); // 終了後硬直
        mController.ChangeState(new CommandoIdleState(mController));
    }
}

public class CommandoStunState : CommandoBaseState
{
    private float _duration;
    private float _timer;
    public CommandoStunState(CommandoController core, float duration) : base(core) { _duration = duration; }
    public override void Enter() { mController.SetWeaponActive(false, 0); _timer = 0f; }
    public override void Update()
    {
        _timer += Time.deltaTime;
        mController.Rb.linearVelocity = Vector2.Lerp(mController.Rb.linearVelocity, Vector2.zero, Time.deltaTime * 5f);
        if (_timer >= _duration) mController.ChangeState(new CommandoIdleState(mController));
    }
}

// ---------------------------------------------------------
// Phase2 グレネード / 閃光手榴弾投げ
// ---------------------------------------------------------
public class CommandoGrenadeThrowState : CommandoBaseState
{
    public CommandoGrenadeThrowState(CommandoController core) : base(core) { }

    public override void Enter()
    {
        mController.Rb.linearVelocity = Vector2.zero;
        mController.ShouldAutoFacing = false;
        ThrowSequence().Forget();
    }

    private async UniTaskVoid ThrowSequence()
    {
        var token = mController.GetCancellationTokenOnDestroy();

        try
        {
            // プレイヤーを向く
            if (mController.target != null)
            {
                Vector2 dir = (mController.target.position - mController.transform.position).normalized;
                mController.ForceFacing(dir);
            }

            // 少し溜め
            await UniTask.Delay(TimeSpan.FromSeconds(0.4f), cancellationToken: token);

            // 通常グレネード or 閃光手榴弾を確率で選択
            bool useNormalGrenade = Random.value < mController.normalGrenadeRatio;

            if (useNormalGrenade)
            {
                // --- 通常グレネード: プレイヤーに向けて投げる ---
                if (mController.grenadeThrowPrefab != null && mController.target != null)
                {
                    Vector2 toPlayer = (mController.target.position - mController.transform.position);
                    // 放物線を意識した速度（ざっくり距離に応じてスピード調整）
                    float throwSpeed = Mathf.Clamp(toPlayer.magnitude * 1.5f, 8f, 18f);
                    Vector2 throwDir = toPlayer.normalized;

                    GameObject grenade = ObjectPoolManager.Instance.GetObject(
                        mController.grenadeThrowPrefab,
                        mController.transform.position,
                        Quaternion.identity);

                    var rb = grenade.GetComponent<Rigidbody2D>();
                    if (rb != null) rb.linearVelocity = throwDir * throwSpeed;
                }
            }
            else
            {
                // --- 閃光手榴弾: 自分の傍（ランダムな向き）に転がす ---
                if (mController.flashGrenadePrefab != null)
                {
                    // 自分のすぐ近くにランダム方向で転がす
                    Vector2 rollDir = Random.insideUnitCircle.normalized;
                    float rollSpeed = Random.Range(3f, 6f);

                    GameObject flashGrenade = ObjectPoolManager.Instance.GetObject(
                        mController.flashGrenadePrefab,
                        mController.transform.position,
                        Quaternion.identity);

                    var fg = flashGrenade.GetComponent<FlashGrenade>();
                    if (fg != null)
                    {
                        // Controllerにセットされている flashEffectPrefab を渡す
                        fg.flashEffectPrefab = mController.flashEffectPrefab;
                        fg.Launch(rollDir * rollSpeed);
                    }
                    else
                    {
                        // FlashGrenadeコンポーネントがない場合は直接velocityだけ入れる
                        var rb = flashGrenade.GetComponent<Rigidbody2D>();
                        if (rb != null) rb.linearVelocity = rollDir * rollSpeed;
                    }
                }
            }

            // 投げ後の硬直
            await UniTask.Delay(TimeSpan.FromSeconds(0.6f), cancellationToken: token);
        }
        catch (System.OperationCanceledException) { }
        finally
        {
            if (mController != null && mController.gameObject.activeInHierarchy)
            {
                mController.ShouldAutoFacing = true;
                mController.ChangeState(new CommandoObserveState(mController));
            }
        }
    }
}

// =========================================================
// 必殺技: 戦車砲撃 (Ultimate)
// =========================================================
public class CommandoUltimateState : CommandoBaseState
{
    public CommandoUltimateState(CommandoController core) : base(core) { }

    public override void Enter()
    {
        mController.Rb.linearVelocity = Vector2.zero;
        mController.ShouldAutoFacing = false;
        UltimateSequence().Forget();
    }

    private async UniTaskVoid UltimateSequence()
    {
        var token = mController.GetCancellationTokenOnDestroy();

        try
        {
            // ---- 必殺発動演出 ----
            await mController.PlaySpecialReadySequence();

            // ---- Commando が画面上部の外へ移動 ----
            float topExit = mController.maxScreenY + 3f;
            Vector2 exitPos = new Vector2(mController.transform.position.x, topExit);

            while (Vector2.Distance(mController.Rb.position, exitPos) > 0.01f)
            {
                Vector2 nextPos = Vector2.MoveTowards(
                    mController.Rb.position,
                    exitPos,
                    mController.ultimateMoveSpeed * Time.fixedDeltaTime);

                mController.Rb.MovePosition(nextPos);
                await UniTask.Yield(PlayerLoopTiming.FixedUpdate, token);
            }
            mController.Rb.position = exitPos; // 最後にピッタリ合わせる

            // ---- 戦車スポーン（画面上部外） ----
            if (mController.tankPrefab == null)
            {
                // 戦車Prefabが未設定の場合はスキップしてそのまま終了
                mController.gameObject.SetActive(true);
                mController.transform.position = exitPos;
                await FinalReturn(token, exitPos);
                return;
            }

            if (mController.tankCallSound != null)
                AudioManager.Instance.PlaySE(mController.tankCallSound);

            // 戦車は画面上部の中央あたりに落とす
            float tankSpawnX = (mController.minScreenX + mController.maxScreenX) * 0.5f;
            float tankSpawnY = mController.maxScreenY + 4f;
            Vector2 tankSpawnPos = new Vector2(tankSpawnX, tankSpawnY);

            GameObject tankObj = ObjectPoolManager.Instance.GetObject(
                mController.tankPrefab, tankSpawnPos, Quaternion.identity);

            // 戦車が画面端ギリギリの位置（上端 – 少し内側）まで移動
            float tankTargetY = mController.maxScreenY - 0.5f;
            Vector2 tankTargetPos = new Vector2(tankSpawnX, tankTargetY);

            var tankRb = tankObj.GetComponent<Rigidbody2D>();

            // -- 戦車を所定位置まで落とす (移動音付き) --
            await MoveTankWithSoundAsync(tankObj, tankTargetPos, 1f, token);
            if (tankRb != null) tankRb.linearVelocity = Vector2.zero;

            // 砲台 Transform を取得（CommandoTankコンポーネントからの安全な取得を優先）
            var tankComponent = tankObj.GetComponent<CommandoTank>();
            Transform cannonBarrel = tankComponent != null && tankComponent.cannonBarrel != null
                ? tankComponent.cannonBarrel
                : tankObj.transform.Find("cannonBarrel"); // 古いPrefab用のフォールバック

            Transform firePoint = tankComponent != null && tankComponent.firePoint != null
                ? tankComponent.firePoint
                : (cannonBarrel != null ? cannonBarrel.Find("firePoint") : null);

            // 砲台を常にプレイヤーに向けるタスクを開始
            UpdateCannonRotationAsync(cannonBarrel, token).Forget();

            // ---- 3. 砲撃ループ ----
            int totalShots = mController.CannonTotalAmmo;
            int shotsFired = 0;
            float shotInterval = mController.CannonShotInterval;
            float burstInterval = mController.CannonBurstInterval;

            while (shotsFired < totalShots)
            {
                // バーストあたりの発射数をランダムに決定し、残り総弾数を超えないように調整
                int shotsThisBurst = Random.Range(mController.CannonMinShotsPerBurst, mController.CannonMaxShotsPerBurst + 1);
                shotsThisBurst = Mathf.Min(shotsThisBurst, totalShots - shotsFired);

                for (int shot = 0; shot < shotsThisBurst; shot++)
                {
                    if (mController.target != null)
                    {
                        if (mController.fireFlashEffect != null && firePoint != null)
                        {
                            EffectManager.Instance.PlayEffect(mController.fireFlashEffect, firePoint.position, 2f);
                        }
                        // プレイヤーの現在位置へ向けて弾を飛ばす。到着したら爆発
                        Vector2 targetPos = mController.target.position;

                        // startPosの決定: firePoint -> cannonBarrel -> tankObj の優先順位で取得
                        Vector2 startPos;
                        if (firePoint != null) startPos = firePoint.position;
                        else if (cannonBarrel != null) startPos = cannonBarrel.position;
                        else startPos = tankObj.transform.position;

                        FireCannonBulletAsync(startPos, targetPos, token).Forget();
                    }

                    shotsFired++;
                    await UniTask.Delay(
                        System.TimeSpan.FromSeconds(shotInterval), cancellationToken: token);
                }

                // バースト間インターバル（撃ち切っていない場合のみ）
                if (shotsFired < totalShots)
                {
                    await UniTask.Delay(
                        System.TimeSpan.FromSeconds(burstInterval), cancellationToken: token);
                }
            }

            // ---- 戦車を画面上部外へ退場 ----
            Vector2 tankExitPos = new Vector2(tankObj.transform.position.x, mController.maxScreenY + 5f);
            await MoveTankWithSoundAsync(tankObj, tankExitPos, 1f, token);

            ObjectPoolManager.Instance.Release(tankObj);

            // ---- Commando が画面上部から再登場 ----
            await FinalReturn(token, exitPos);
        }
        catch (System.OperationCanceledException)
        {

        }
    }

    // 爆発判定（OverlapCircleAll）
    private void FireExplosion(Vector2 pos)
    {
        float radius = mController.CannonExplosionRadius;
        int damage = mController.Status.AdjustedAttackPower;

        // エフェクト
        if (mController.explosionEffect != null)
            EffectManager.Instance.PlayEffect(mController.explosionEffect, pos, radius);

        // ダメージ判定
        Collider2D[] hits = Physics2D.OverlapCircleAll(pos, radius);
        foreach (var c in hits)
        {
            if (c != null && c.CompareTag("Player"))
            {
                var dmg = c.GetComponent<IDamageable>();
                if (dmg != null) dmg.TakeDamage(damage);
            }
        }
    }

    // 砲台を常にプレイヤーへ向けるタスク
    private async UniTaskVoid UpdateCannonRotationAsync(Transform cannonBarrel, System.Threading.CancellationToken token)
    {
        try
        {
            while (cannonBarrel != null && cannonBarrel.gameObject.activeInHierarchy)
            {
                if (mController.target != null)
                {
                    Vector2 toPlayer = mController.target.position - cannonBarrel.position;
                    float angle = Mathf.Atan2(toPlayer.y, toPlayer.x) * Mathf.Rad2Deg;
                    cannonBarrel.rotation = Quaternion.Euler(0f, 0f, angle + 90f);
                }
                await UniTask.Yield(PlayerLoopTiming.Update, token);
            }
        }
        catch (System.OperationCanceledException) { }
    }

    // 戦車の移動とSE管理
    private async UniTask MoveTankWithSoundAsync(GameObject tankObj, Vector2 targetPos, float moveSpeed, System.Threading.CancellationToken token)
    {
        AudioSource moveAudio = tankObj.GetComponent<AudioSource>();
        if (moveAudio == null) moveAudio = tankObj.AddComponent<AudioSource>();

        if (mController.tankMoveSound != null)
        {
            moveAudio.clip = mController.tankMoveSound;
            moveAudio.loop = true;
            moveAudio.volume = 1f;
            moveAudio.Play();
        }

        var tankRb = tankObj.GetComponent<Rigidbody2D>();

        if (tankRb != null)
        {
            while (Vector2.Distance(tankRb.position, targetPos) > 0.01f)
            {
                Vector2 nextPos = Vector2.MoveTowards(tankRb.position, targetPos, moveSpeed * Time.fixedDeltaTime);
                tankRb.MovePosition(nextPos);
                await UniTask.Yield(PlayerLoopTiming.FixedUpdate, token);
            }
            tankRb.position = targetPos;
        }
        else
        {
            // 万が一Rigidbodyがない場合のフォールバック
            while ((Vector2)tankObj.transform.position != targetPos)
            {
                tankObj.transform.position = Vector2.MoveTowards(tankObj.transform.position, targetPos, moveSpeed * Time.deltaTime);
                await UniTask.Yield(PlayerLoopTiming.Update, token);
            }
        }

        // 到着後フェードアウト
        if (moveAudio.isPlaying)
        {
            float fadeTime = 0.5f;
            float elapsed = 0f;
            while (elapsed < fadeTime)
            {
                elapsed += Time.deltaTime;
                moveAudio.volume = Mathf.Lerp(1f, 0f, elapsed / fadeTime);
                await UniTask.Yield(PlayerLoopTiming.Update, token);
            }
            moveAudio.Stop();
        }
    }

    // 砲弾を飛ばして着弾時に爆発させるタスク
    private async UniTaskVoid FireCannonBulletAsync(Vector2 startPos, Vector2 targetPos, System.Threading.CancellationToken token)
    {
        GameObject bullet = null;
        if (mController.cannonBulletPrefab != null)
        {
            bullet = ObjectPoolManager.Instance.GetObject(mController.cannonBulletPrefab, startPos, Quaternion.identity);

            // 弾自体の当たり判定は不要なため、WeaponHitbox等があれば無効化する
            var colls = bullet.GetComponentsInChildren<Collider2D>();
            foreach (var col in colls) col.enabled = false;
        }

        float dist = Vector2.Distance(startPos, targetPos);
        float duration = dist / mController.flySpeed;
        float elapsed = 0f;

        try
        {
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                if (bullet != null)
                {
                    bullet.transform.position = Vector2.Lerp(startPos, targetPos, elapsed / duration);
                    // 進行方向へ向ける
                    Vector2 dir = (targetPos - startPos).normalized;
                    float angle = Mathf.Atan2(dir.y, dir.x) * Mathf.Rad2Deg;
                    bullet.transform.rotation = Quaternion.Euler(0, 0, angle - 90f);
                }
                await UniTask.Yield(PlayerLoopTiming.Update, token);
            }

            if (bullet != null)
            {
                bullet.transform.position = targetPos;
                ObjectPoolManager.Instance.Release(bullet);
            }

            // 着弾時に爆発する
            FireExplosion(targetPos);
        }
        catch (System.OperationCanceledException)
        {
            if (bullet != null && bullet.activeInHierarchy) ObjectPoolManager.Instance.Release(bullet);
        }
    }

    // Commando を画面上から降下させて復帰
    private async UniTask FinalReturn(System.Threading.CancellationToken token, Vector2 returnPos)
    {
        // 上部枠外に配置して再表示
        mController.gameObject.SetActive(true);
        mController.Rb.position = returnPos;
        mController.Rb.linearVelocity = Vector2.zero;

        float targetY = mController.maxScreenY - 2f;
        Vector2 landPos = new Vector2(returnPos.x, targetY);

        while (Vector2.Distance(mController.Rb.position, landPos) > 0.01f)
        {
            Vector2 nextPos = Vector2.MoveTowards(
                mController.Rb.position,
                landPos,
                mController.ultimateMoveSpeed * Time.fixedDeltaTime);

            mController.Rb.MovePosition(nextPos);
            await UniTask.Yield(PlayerLoopTiming.FixedUpdate, token);
        }
        mController.Rb.position = landPos;

        mController.ShouldAutoFacing = true;
        mController.ChangeState(new CommandoIdleState(mController));
    }
}
