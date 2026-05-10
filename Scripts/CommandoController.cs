using UnityEngine;
using System.Collections.Generic;

[RequireComponent(typeof(Rigidbody2D))]
[RequireComponent(typeof(EnemyStatus))]
public class CommandoController : S_EnemyBaseController
{
    [Header("基本設定")]
    public float stunRatio = 0.3f; // スタンの確率
    public float stunRatioGrowRate = 0.1f; // スタン確率の成長率
    private float _currentStunRatio;
    [Header("AI設定")]
    public float observeMinTime = 1.0f;
    public float observeMaxTime = 2.0f;

    [Header("フェーズ設定")]
    [Tooltip("フェーズ2開始ライン（N2解禁）")] public float phase2Threshold = 0.7f;
    [Tooltip("フェーズ3開始ライン（N3解禁）")] public float phase3Threshold = 0.4f;

    [Header("モード切替設定")]
    public float meleeToRangedRatio = 0.5f;
    public float rangedToMeleeRatio = 0.5f;
    public float specialAttackChancePerSecond = 0.3f; // 1秒間に特殊攻撃が暴発する確率

    [Header("近接設定")]
    public float meleeRange = 2.0f;
    public AudioClip meleeAttackSound;
    public GameObject meleeWeaponSprite; // 近接武器画像

    [Header("遠距離設定")]
    public Transform gunPivot;  //発射地点
    public GameObject bulletPrefab;  //弾のプレハブ
    public float shootRange = 8.0f;  //射程距離
    [SerializeField] private float gunFireRate = 0.5f;  //通常時の連射間隔
    [SerializeField] private float rifleFireRate = 0.1f;  //高密度連射時の連射間隔
    public float CurrentFireRate { get; private set; }
    public int gunMaxAmmo = 15;  //通常時の弾倉
    public int rifleMaxAmmo = 40;  //高密度連射時の弾倉
    public int CurrentMaxAmmo { get; private set; }
    public int gunMaxBurstCount = 5;  //通常時のバースト弾数
    public int rifleMaxBurstCount = 10;  //高密度連射時のバースト弾数
    public int CurrentBurstCount { get; private set; }
    public float firedInterval = 1f; // 連続射撃後のインターバル
    public float reloadTime = 2.0f; // リロード時間
    public float bulletSpeed = 40f; // 弾速
    public AudioClip gunShootSound;
    public AudioClip rifleShootSound;
    public AudioClip reloadSound;
    public GameObject rangedWeaponSprite; // 射撃武器画像

    [Header("移動速度設定")]
    public float meleeChaseSpeed = 10f;     // 近接で追いかける速度
    public float rangedApproachSpeed = 3f;  // 射撃時に近づく速度
    public float rangedBackStepSpeed = 2f;  // 射撃時に下がる速度

    [Header("Phase 2: グレネード投げ設定")]
    public GameObject grenadeThrowPrefab;    // グレネードPrefab
    public GameObject flashGrenadePrefab;    // 閃光手榴弾Prefab
    public GameObject flashEffectPrefab;     // 閃光エフェクトPrefab
    [Tooltip("Phase2観察中にグレネードを投げる確率 (0.0〜1.0)")]
    public float phase2GrenadeChance = 0.3f; // タイマー終了時の確率
    [Tooltip("通常グレネードの確率 (0.0〜1.0)。残りが閃光手榴弾")]
    public float normalGrenadeRatio = 0.5f;

    [Header("スキルクールダウン設定")]
    // Sp1, Sp2, Sp3の順
    public float[] abilityCooldowns = new float[] { 5.0f, 5.0f, 8.0f };
    private float[] _currentCooldowns = new float[3];
    private float _globalCooldown = 10.0f; // 特殊行動後の共通クールダウン
    private float _lastAbilityTime = -10f;

    [Header("特殊攻撃1: 砲撃 (Sp1)")]
    public GameObject artilleryMarkerPrefab;
    public GameObject bombPrefab;
    public AudioClip artilleryVoice;
    public AudioClip jetNoise;
    public AudioClip bombSound;
    public int baseBombCount = 30;
    public int BombCount { get; private set; }
    public float baseExplosionRadius = 2.5f;
    public float explosionRadius { get; private set; }
    [Tooltip("砲撃生成ベース間隔")]
    public float baseBombInterval = 0.1f;
    public float BombInterval { get; private set; }
    [Tooltip("警告表示から爆発までの時間")]
    public float artilleryDelay = 1f;

    [Header("エフェクトデータ")]
    [SerializeField] public EffectDataSO explosionEffect;  // 爆発エフェクト
    [SerializeField] public EffectDataSO warningEffect;    // 予兆エフェクト


    [Header("特殊攻撃2: リロードバースト (Sp2)")]
    public float burstFireRate = 0.1f; // かなり高速
    public AudioClip burstVoice;

    [Header("特殊攻撃3: 増援要請 (Sp3新仕様)")]
    public GameObject reinforcementPrefab;
    public AudioClip callReinforcementSound;
    [Tooltip("一度に呼ぶ増援のベース数")]
    public int baseReinforcementCount = 2;
    public int ReinforcementCount { get; private set; }
    public List<Transform> reinforcementSpawnPoints; // 増援の出現ポイントリスト

    [Header("必殺技: 戦車砲撃 (Ultimate)")]
    public GameObject tankPrefab;                    // 戦車 Prefab
    public AudioClip tankCallSound;                  // 呼び出しSE
    public AudioClip tankMoveSound;                  // 移動SE
    public EffectDataSO fireFlashEffect;           // 砲撃エフェクト
    public GameObject cannonBulletPrefab;            // 砲撃の弾（飛翔用）
    public float ultimateMoveSpeed = 12.0f;  // Commando本体の入退場移動速度
    [Tooltip("砲弾の速度")]
    public float flySpeed = 30f;
    [Tooltip("バーストで撃つ最小弾数")]
    public int baseCannonMinShotsPerBurst = 2;
    public int CannonMinShotsPerBurst { get; private set; }
    [Tooltip("バーストで撃つ最大弾数")]
    public int baseCannonMaxShotsPerBurst = 4;
    public int CannonMaxShotsPerBurst { get; private set; }
    [Tooltip("弾の発射間隔 (秒)")]
    public float baseCannonShotInterval = 0.5f;
    public float CannonShotInterval { get; private set; }
    [Tooltip("バースト間のインターバル (秒)")]
    public float baseCannonBurstInterval = 1f;
    public float CannonBurstInterval { get; private set; }
    [Tooltip("砲撃の総弾数")]
    public int baseCannonTotalAmmo = 20;
    public int CannonTotalAmmo { get; private set; }
    [Tooltip("砲撃の爆発半径")]
    public float baseCannonExplosionRadius = 2.5f;
    public float CannonExplosionRadius { get; private set; }

    // 内部ステート
    public int CurrentPhase { get; private set; } = 1;
    public int CurrentAmmo { get; set; }

    protected override void Start()
    {
        // 初期弾数
        CurrentMaxAmmo = gunMaxAmmo;
        CurrentBurstCount = gunMaxBurstCount;
        CurrentAmmo = CurrentMaxAmmo;
        CurrentFireRate = gunFireRate;

        base.Start();

        // 初期ステート: 待機
        ChangeState(new CommandoIdleState(this));
    }

    protected override void Update()
    {
        base.Update();
        CheckPhaseUpdate();
        UpdateCooldowns();
    }

    private void CheckPhaseUpdate()
    {
        if (Status == null) return;

        float hpRatio = (float)Status.CurrentLife / Status.AdjustedMaxLife;

        if (CurrentPhase == 1 && hpRatio <= phase2Threshold)
        {
            CurrentPhase = 2;
            OnPhaseChange();
            Debug.Log("Commando: Phase 2 Start!");
        }
        else if (CurrentPhase == 2 && hpRatio <= phase3Threshold)
        {
            CurrentPhase = 3;
            OnPhaseChange();
            Debug.Log("Commando: Phase 3 Start!");
        }
    }

    private void UpdateCooldowns()
    {
        for (int i = 0; i < _currentCooldowns.Length; i++)
        {
            if (_currentCooldowns[i] > 0) _currentCooldowns[i] -= Time.deltaTime;
        }
    }

    public void OnPhaseChange()
    {
        if (CurrentPhase == 3)
        {
            CurrentFireRate = rifleFireRate;
            CurrentMaxAmmo = rifleMaxAmmo;
            CurrentBurstCount = rifleMaxBurstCount;
        }
    }

    public override void OnParried(Vector2 knockbackForce)
    {
        SetWeaponActive(false, 0);

        // if (noStun) return;
        //  確率でスタンに
        int stunOdds = Random.Range(0, 100);
        if (stunOdds < _currentStunRatio * 100)
        {
            ChangeState(new CommandoStunState(this, 2.0f));
            base.OnParried(knockbackForce); // Knockback only on stun
            _currentStunRatio = stunRatio;
        }
        else
        {
            //スタンしなかったら確率を増加させる
            _currentStunRatio += stunRatioGrowRate;
        }
    }

    public void SetStunRatio(float ratio)
    {
        _currentStunRatio = ratio;
    }

    public bool CanUseUltimate()
    {
        // Eliteの時は必殺技なし
        if (Status.rank == EnemyRank.Elite) return false;
        return Status.IsSpecialReady;
    }

    public bool CheckAbilityAvailable(int skillIndex)
    {
        // グローバルクールダウンチェック
        if (Time.time - _lastAbilityTime < _globalCooldown) return false;
        // 個別クールダウンチェック
        if (skillIndex < 0 || skillIndex >= _currentCooldowns.Length) return false;
        return _currentCooldowns[skillIndex] <= 0;
    }

    public void UseAbility(int skillIndex)
    {
        if (skillIndex >= 0 && skillIndex < _currentCooldowns.Length)
        {
            _currentCooldowns[skillIndex] = abilityCooldowns[skillIndex];
        }
        _lastAbilityTime = Time.time;
    }

    // 武器画像の変更
    public void SwitchWeaponSprite(bool isMelee)
    {
        if (_weaponSprite == null) return;

        if (isMelee)
        {
            if (meleeWeaponSprite != null) meleeWeaponSprite.SetActive(true);
            if (rangedWeaponSprite != null) rangedWeaponSprite.SetActive(false);
        }
        else
        {
            if (rangedWeaponSprite != null) rangedWeaponSprite.SetActive(true);
            if (meleeWeaponSprite != null) meleeWeaponSprite.SetActive(false);
        }
    }

    protected override void ApplyDifficultySettings()
    {
        BombCount = baseBombCount;
        BombInterval = baseBombInterval;
        explosionRadius = baseExplosionRadius;
        CannonMinShotsPerBurst = baseCannonMinShotsPerBurst;
        CannonMaxShotsPerBurst = baseCannonMaxShotsPerBurst;
        CannonShotInterval = baseCannonShotInterval;
        CannonBurstInterval = baseCannonBurstInterval;
        CannonTotalAmmo = baseCannonTotalAmmo;
        CannonExplosionRadius = baseCannonExplosionRadius;
        ReinforcementCount = baseReinforcementCount;

        if (DifficultyManager.Instance == null) return;

        switch (DifficultyManager.Instance.CurrentDifficulty)
        {
            case DifficultyManager.DifficultyLevel.Easy:
                BombCount -= 10;
                BombInterval *= 1.5f;
                explosionRadius *= 0.75f;
                CannonMinShotsPerBurst -= 1;
                CannonMaxShotsPerBurst -= 1;
                CannonShotInterval *= 1.225f;
                CannonBurstInterval *= 1.225f;
                CannonTotalAmmo -= 10;
                CannonExplosionRadius *= 0.75f;
                ReinforcementCount -= 1;
                break;
            case DifficultyManager.DifficultyLevel.Normal:
                break;
            case DifficultyManager.DifficultyLevel.Hard:
                BombCount += 10;
                BombInterval *= 0.5f;
                explosionRadius *= 1.225f;
                CannonMinShotsPerBurst += 2;
                CannonMaxShotsPerBurst += 4;
                CannonShotInterval *= 0.5f;
                CannonBurstInterval *= 0.5f;
                CannonTotalAmmo += 10;
                CannonExplosionRadius *= 1.225f;
                ReinforcementCount += 1;
                break;
        }
    }
}
