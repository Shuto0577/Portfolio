using UnityEngine;
using Cysharp.Threading.Tasks;
using System;

[RequireComponent(typeof(Rigidbody2D))]
[RequireComponent(typeof(EnemyStatus))]
public abstract class S_EnemyBaseController : MonoBehaviour
{
    // --- 向きのEnum定義 ---
    public enum Facing { Down, Up, Right, Left }

    // --- 共通使用項目 ---
    [HideInInspector] public Transform target; // プレイヤーの参照
    [SerializeField] private WeaponHitbox _weaponHitBox;  //武器の当たり判定
    public SpriteRenderer _weaponSprite;  //武器の見た目
    [SerializeField] protected Transform _weaponPivot;  //武器の回転軸

    [Header("必殺技発動演出(BOSS限定)")]
    [SerializeField] private EffectDataSO specialStartEffect;
    [Tooltip("発動時に時間を止める（ヒットストップ）か")]
    [SerializeField] private bool useTimeStop = true;
    [Tooltip("演出の待機時間（秒）")]
    [SerializeField] private float startEffectWaitTime = 0.5f;

    [Tooltip("画面を暗くするためのオブジェクト（SpriteRenderer等）")]
    [SerializeField] private GameObject darkOverlayObject;

    [Header("AI知能設定（壁避けセンサー）")]
    [Tooltip("壁避けを有効にするか")]
    public bool useObstacleAvoidance = true;
    [Tooltip("EdgeWallや破壊対象物が含まれるレイヤー")]
    public LayerMask obstacleLayer;
    [Tooltip("どれくらい先の壁まで検知するか")]
    public float avoidanceLookAhead = 1.5f;

    // --- 内部参照 ---
    public Rigidbody2D Rb { get; private set; }
    public EnemyStatus Status { get; private set; }
    public Animator Anim { get; protected set; }
    private S_EnemyState _currentState;

    /// <summary>
    /// falseのとき、Update()内のHandleFacing()自動呼び出しをスキップする。
    /// 攻撃ステートなどでForceFacingを使って向きを制御したい場合、子クラスからfalseにセットする。
    /// </summary>
    public bool ShouldAutoFacing { get; set; } = true;

    // 壁検知用
    private RaycastHit2D[] _rayResults = new RaycastHit2D[10];
    private ContactFilter2D _wallFilter;

    // 画面端の座標
    public float minScreenX { get; private set; }
    public float maxScreenX { get; private set; }
    public float minScreenY { get; private set; }
    public float maxScreenY { get; private set; }

    // レイヤー（敵すり抜け用）
    private int _playerLayer;
    private int _enemyLayer;

    // Enum化した向きプロパティ
    public Facing FacingDirection { get; private set; }

    protected virtual void Awake()
    {
        Rb = GetComponent<Rigidbody2D>();
        Status = GetComponent<EnemyStatus>();
        Anim = GetComponentInChildren<Animator>(); // 子要素のアニメーターを取得

        // 壁検知フィルタ設定
        _wallFilter = new ContactFilter2D();
        _wallFilter.useTriggers = false; // Trigger以外のColliderのみ検知   
    }

    protected virtual void OnEnable()
    {
        // Awakeより先に呼ばれた場合の保険
        if (Status == null) Status = GetComponent<EnemyStatus>();
        if (Rb == null) Rb = GetComponent<Rigidbody2D>();
        if (Anim == null) Anim = GetComponentInChildren<Animator>();

        if (Status != null)
        {
            Status.ResetHp(); // HPを最大まで回復
            Status.manualDeath = false; // 死に方フラグをリセット
        }

        // ターゲット再取得
        if (target == null)
        {
            var player = GameObject.FindGameObjectWithTag("Player");
            if (player != null) target = player.transform;
        }

        IgnoreWallCollision = false;
        ShouldAutoFacing = true;

        ApplyDifficultySettings();
    }

    protected virtual void OnDisable()
    {
        // 共通の後片付け用
    }

    public void StopAction()
    {
        _currentState?.Exit();
        _currentState = null;
        if (Rb != null)
        {
            Rb.linearVelocity = Vector2.zero;
            Rb.angularVelocity = 0f;
        }
    }

    protected virtual void Start()
    {
        // ターゲット取得（簡易的にTag検索）
        var player = GameObject.FindGameObjectWithTag("Player");
        if (player != null) target = player.transform;
        ApplyDifficultySettings();

        if (_weaponHitBox != null) _weaponHitBox.gameObject.SetActive(false);
        // 開始時は確実に非表示にしておく
        if (darkOverlayObject != null) darkOverlayObject.SetActive(false);

        // 画面端の取得
        if (Camera.main != null)
        {
            minScreenX = Camera.main.ViewportToWorldPoint(new Vector3(1f / 4.2f, 0, Camera.main.nearClipPlane)).x;
            maxScreenX = Camera.main.ViewportToWorldPoint(new Vector3(1f - (1f / 4.2f), 0, Camera.main.nearClipPlane)).x;
            minScreenY = Camera.main.ViewportToWorldPoint(new Vector3(0, 0, Camera.main.nearClipPlane)).y;
            maxScreenY = Camera.main.ViewportToWorldPoint(new Vector3(0, 1, Camera.main.nearClipPlane)).y;
        }

        // レイヤー取得（敵との衝突無視用：設定されていなければ無視）
        _playerLayer = LayerMask.NameToLayer("Player");
        _enemyLayer = LayerMask.NameToLayer("Enemy");
    }

    protected virtual void Update()
    {
        if (GameMaster.Instance != null && GameMaster.Instance.CurrentState != GameMaster.GameState.Gameplay)
        {
            if (Rb != null) Rb.linearVelocity = Vector2.zero;
            return;
        }

        _currentState?.Update();
        if (ShouldAutoFacing) HandleFacing();
    }

    protected virtual void FixedUpdate()
    {
        if (GameMaster.Instance != null && GameMaster.Instance.CurrentState != GameMaster.GameState.Gameplay)
        {
            if (Rb != null) Rb.linearVelocity = Vector2.zero;
            return;
        }

        _currentState?.FixedUpdate();
        CheckWallCollision();
    }

    /// <summary>
    /// 目的地へのベクトルを渡し、壁があれば壁に沿って平行に滑るベクトルを返す
    /// </summary>
    public Vector2 GetAvoidanceVelocity(Vector2 desiredDirection, float speed)
    {
        if (!useObstacleAvoidance || desiredDirection == Vector2.zero)
            return desiredDirection.normalized * speed;

        Vector2 pos = transform.position;
        Vector2 dir = desiredDirection.normalized;

        // 正面に1本だけレイを飛ばす
        RaycastHit2D hit = Physics2D.Raycast(pos, dir, avoidanceLookAhead, obstacleLayer);

        if (hit.collider != null)
        {
            // 壁の法線（normal）成分を進行ベクトルから引き算することで、壁に沿った平行なベクトルを作る
            Vector2 slideDir = dir - Vector2.Dot(dir, hit.normal) * hit.normal;

            // もし壁に真正面からぶつかってスライド先がない場合は、法線の90度横に逃げる
            if (slideDir.sqrMagnitude < 0.01f)
            {
                slideDir = new Vector2(-hit.normal.y, hit.normal.x);
            }

            return slideDir.normalized * speed;
        }

        return dir * speed;
    }

    /// <summary>
    /// ターゲットとの間に壁がないか（射線が通っているか）を確認する
    /// </summary>
    public bool HasLineOfSight(Transform targetObj)
    {
        if (targetObj == null) return false;

        Vector2 pos = transform.position;
        Vector2 targetPos = targetObj.position;
        Vector2 dir = targetPos - pos;
        float distance = dir.magnitude;

        // 自身とターゲットの間に障害物(壁)があるかレイキャストを飛ばす
        RaycastHit2D hit = Physics2D.Raycast(pos, dir.normalized, distance, obstacleLayer);

        // colliderがnullなら（壁に当たらなければ）射線が通っている
        return hit.collider == null;
    }

    public virtual void OnDamageDealt()
    {
        // ゲージ増加処理
        Status.OnDamageDealt();
    }

    // パリィされたときの処理（ノックバック + スタン）
    // 子クラスで特殊な挙動が必要な場合はoverrideする
    public virtual void OnParried(Vector2 knockbackForce)
    {
        // 簡易ノックバック (質量考慮)
        float mass = Rb.mass > 0 ? Rb.mass : 1.0f;
        Rb.linearVelocity = knockbackForce / mass;
    }

    // Kinematic時の壁すり抜け防止
    private void CheckWallCollision()
    {
        if (Rb.bodyType != RigidbodyType2D.Kinematic) return;

        Vector2 velocity = Rb.linearVelocity;
        if (velocity == Vector2.zero) return;

        // わずかに長めに判定して、壁めり込みを防ぐ
        float distance = velocity.magnitude * Time.fixedDeltaTime + 0.1f;
        // 進行方向に壁があるかキャスト
        int count = Rb.Cast(velocity.normalized, _wallFilter, _rayResults, distance);

        for (int i = 0; i < count; i++)
        {
            Collider2D col = _rayResults[i].collider;
            // EdgeWallのTagを直接判定する
            if (col != null && (col.CompareTag("EdgeWall") || col.CompareTag("Wall") || col.CompareTag("DestructiveObject")))
            {
                Vector2 normal = _rayResults[i].normal;
                if (Vector2.Dot(velocity, normal) < 0)
                {
                    Vector2 projection = Vector2.Dot(velocity, normal) * normal;
                    Rb.linearVelocity = velocity - projection;
                    velocity = Rb.linearVelocity; // 複数ヒットに対応するため速度を更新
                }
            }
        }
    }

    // プレイヤーとの当たり判定を設定する（当たり判定のON/OFF）
    public void IgnorePlayerCollision(bool ignore)
    {
        if (_playerLayer != -1 && _enemyLayer != -1)
        {
            Physics2D.IgnoreLayerCollision(_playerLayer, _enemyLayer, ignore);
        }
    }

    // 壁との当たり判定を設定する（当たり判定のON/OFF）
    public bool IgnoreWallCollision { get; set; } = false;

    public void ChangeState(S_EnemyState newState)
    {
        _currentState?.Exit();
        _currentState = newState;
        _currentState.Enter();
    }

    // 攻撃中のアニメーションで当たり判定を出現させ、ダメージを持たせる
    public void SetWeaponActive(bool isActive, int damage)
    {
        if (_weaponHitBox != null)
        {
            _weaponHitBox.SetDamage(damage);
            _weaponHitBox.gameObject.SetActive(isActive);
        }
    }

    // 移動方向から向きを更新する
    public void HandleFacing()
    {
        // 敵は入力ではなく「現在の速度（移動方向）」を見て向きを決める
        Vector2 velocity = Rb.linearVelocity;

        // ほとんど動いていないときは向きを変えない（待機中など）
        if (velocity.sqrMagnitude < 0.1f) return;

        UpdateFacingFromVector(velocity);
    }

    // 強制的に指定した向きを向かせる
    public void ForceFacing(Vector2 dir)
    {
        if (dir.sqrMagnitude < 0.001f) return;
        UpdateFacingFromVector(dir);
    }

    // 進行方向から向きを更新する
    private void UpdateFacingFromVector(Vector2 dir)
    {
        // 縦移動と横移動、どちらの勢いが強いか判定 (FacingDirectionは互換性のために計算だけしておく)
        if (Mathf.Abs(dir.x) > Mathf.Abs(dir.y))
        {
            if (dir.x > 0) FacingDirection = Facing.Right;
            else FacingDirection = Facing.Left;
        }
        else
        {
            if (dir.y > 0) FacingDirection = Facing.Up;
            else FacingDirection = Facing.Down;
        }

        // 回転処理を適用する
        ApplyRotation(dir);
    }

    // 実際に回転させる処理 (Animator変更廃止 -> スプライト回転)
    private void ApplyRotation(Vector2 dir)
    {
        if (_weaponPivot == null) return;

        // フリップ等はリセット（回転で表現するため）
        // _weaponSprite.flipX = false;
        // _weaponSprite.flipY = false;

        // 角度計算 (Right=0度基準のAtan2 + 90度補正でDown=0度基準に合わせる)
        float angle = Mathf.Atan2(dir.y, dir.x) * Mathf.Rad2Deg;
        transform.rotation = Quaternion.Euler(0f, 0f, angle + 90f);

        // AnimatorへのFacing送信を廃止
    }

    // 0:前(下), 1:後(上), 2:右, 3:左
    public Vector2 GetFacingVector()
    {
        switch (FacingDirection)
        {
            case Facing.Down: return Vector2.down;
            case Facing.Up: return Vector2.up;
            case Facing.Right: return Vector2.right;
            case Facing.Left: return Vector2.left;
            default: return Vector2.down;
        }
    }

    // 必殺技発動演出
    public async UniTask PlaySpecialReadySequence()
    {
        float effectRadius = 7f;
        if (specialStartEffect != null)
        {
            EffectManager.Instance.PlayEffect(specialStartEffect, transform.position, effectRadius);
        }

        if (startEffectWaitTime > 0f)
        {
            if (useTimeStop)
            {
                // GameObjectをアクティブにして画面を暗くする
                if (darkOverlayObject != null) darkOverlayObject.SetActive(true);

                // 時間を完全に停止させる
                float originalTimeScale = Time.timeScale;
                Time.timeScale = 0f;

                // ignoreTimeScale: true を指定して、現実の秒数で待機する
                await UniTask.Delay(TimeSpan.FromSeconds(startEffectWaitTime), ignoreTimeScale: true, cancellationToken: this.GetCancellationTokenOnDestroy());

                // 時間を元に戻す
                Time.timeScale = originalTimeScale;

                // 時間が動き出したら非表示に戻す
                if (darkOverlayObject != null) darkOverlayObject.SetActive(false);
            }
            else
            {
                // 時間を止めない場合
                await UniTask.Delay(TimeSpan.FromSeconds(startEffectWaitTime), cancellationToken: this.GetCancellationTokenOnDestroy());
            }
        }
    }

    // 難易度による設定の変更。子クラスで定義。
    protected virtual void ApplyDifficultySettings() { }
}
