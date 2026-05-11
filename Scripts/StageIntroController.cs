using UnityEngine;
using UnityEngine.InputSystem;
using Cysharp.Threading.Tasks;
using System;
using System.Threading;
using TMPro;
using DG.Tweening;

/// <summary>
/// ArcadeMode限定：ステージ遷移後のイントロ演出。
/// フェードイン完了後、ゲームを進行させずに
/// ステージ名 → 目標テキスト → 「Press to Fight」を表示し、入力を待つ。
///
/// 各ステージシーンに配置する。ArcadeMode かどうかは GameMaster.IsArcadeMode で判定する。
/// StoryMode 遷移時は GameMaster.SetArcadeMode(false) を呼ぶことでイントロをスキップできる。
/// </summary>
public class StageIntroController : MonoBehaviour
{
    // =========================================
    // Inspector設定
    // =========================================

    // ArcadeMode かどうかは GameMaster から読み取る
    private bool IsArcadeMode => GameMaster.Instance != null && GameMaster.Instance.IsArcadeMode;

    [Header("テキスト要素")]
    [Tooltip("ステージ名テキスト（例: R1 - INTERCEPTOR）")]
    [SerializeField] private TextMeshProUGUI stageNameText;
    [Tooltip("目標テキスト（例: Eliminate 20 Enemies）")]
    [SerializeField] private TextMeshProUGUI objectiveText;
    [Tooltip("Press to Fight テキスト")]
    [SerializeField] private TextMeshProUGUI pressToFightText;

    [Header("パネル")]
    [Tooltip("イントロ演出全体を覆うCanvasGroup")]
    [SerializeField] private CanvasGroup introOverlayCanvasGroup;

    [Header("入力設定")]
    [Tooltip("Press to Fight の入力用 InputActionReference（TitleのPressStartと同じSubmit）")]
    [SerializeField] private InputActionReference submitActionRef;

    [Header("アニメーション設定")]
    [SerializeField] private float initialDelay = 0.3f;          // フェードイン後の待機
    [SerializeField] private float stageNameDuration = 0.5f;     // ステージ名アニメ時間
    [SerializeField] private float objectiveDuration = 0.4f;     // 目標テキストアニメ時間
    [SerializeField] private float elementInterval = 0.6f;       // テキスト間の待機
    [SerializeField] private float pressToFightDelay = 0.5f;     // PressToFight表示前の待機
    [SerializeField] private float blinkSpeed = 1.2f;            // PressToFight点滅速度

    [Header("迫力演出設定")]
    [SerializeField] private float stageNameStartScale = 2.5f;   // ステージ名の開始スケール（ズームイン感）
    [SerializeField] private float stageNamePunchStrength = 0.08f;
    [SerializeField] private float objectiveSlideDistance = 200f; // 目標テキストのスライド距離
    [SerializeField] private Ease stageNameEase = Ease.OutExpo;
    [SerializeField] private Ease objectiveEase = Ease.OutCubic;

    [Header("SE設定")]
    [SerializeField] private AudioClip introStageNameSE;         // ステージ名表示時のSE
    [SerializeField] private AudioClip introObjectiveSE;         // 目標表示時のSE
    [SerializeField] private AudioClip introStartSE;             // Press to Fight 入力時のSE

    [Header("BGM設定")]
    [Tooltip("このステージで流すBGM")]
    [SerializeField] private AudioClip stageBGM;

    // =========================================
    // 内部状態
    // =========================================

    private CancellationTokenSource _cts;
    private CancellationTokenSource _blinkCts;
    private bool _submitPressed;
    private bool _isIntroFinished = false;
    private bool _stopBlinking = false; // 点滅を止めるためのフラグ

    /// <summary>イントロ演出が完了したかどうか（他スクリプトから参照可能）</summary>
    public bool IsIntroFinished => _isIntroFinished;

    /// <summary>イントロ演出が完了したときに発火するイベント</summary>
    public event Action OnIntroComplete;

    private void Awake()
    {
        _cts = new CancellationTokenSource();

        // 非ArcadeModeなら即完了扱いにしてオーバーレイを非表示
        if (!IsArcadeMode)
        {
            _isIntroFinished = true;
            if (introOverlayCanvasGroup != null)
                introOverlayCanvasGroup.gameObject.SetActive(false);

            if (stageBGM != null && AudioManager.Instance != null)
                AudioManager.Instance.PlayBGM(stageBGM, 1.0f);

            return;
        }

        // テキストを初期化（非表示）
        SetTextAlpha(stageNameText, 0f);
        SetTextAlpha(objectiveText, 0f);
        SetTextAlpha(pressToFightText, 0f);

        // オーバーレイを表示（ゲームを覆う）
        if (introOverlayCanvasGroup != null)
        {
            introOverlayCanvasGroup.alpha = 1f;
            introOverlayCanvasGroup.interactable = true;
            introOverlayCanvasGroup.blocksRaycasts = true;
            introOverlayCanvasGroup.gameObject.SetActive(true);
        }
    }

    private void Start()
    {
        if (!IsArcadeMode) return;

        // ゲーム進行を停止してイントロ演出を開始
        // テキスト内容のローカライズド取得は PlayIntroSequenceAsync 内で行う
        Time.timeScale = 0f;

        PlayIntroSequenceAsync(_cts.Token).Forget();
    }

    private void OnDestroy()
    {
        _cts?.Cancel();
        _cts?.Dispose();
        _blinkCts?.Cancel();
        _blinkCts?.Dispose();
    }

    // =========================================
    // イントロシーケンス
    // =========================================

    private async UniTask PlayIntroSequenceAsync(CancellationToken token)
    {
        _stopBlinking = false;

        // フェードイン完了を待つ（GameMaster のフェードイン完了後に開始）
        if (GameMaster.Instance != null)
        {
            await UniTask.WaitWhile(() => GameMaster.Instance.IsTransitioning, cancellationToken: token);
        }
        await UniTask.Delay(TimeSpan.FromSeconds(initialDelay), ignoreTimeScale: true, cancellationToken: token);

        // ---- ステージ名を迫力ある演出で表示 ----
        await ShowStageNameAsync(token);

        await UniTask.Delay(TimeSpan.FromSeconds(elementInterval), ignoreTimeScale: true, cancellationToken: token);

        // ---- 目標テキストを横スライドで表示 ----
        await ShowObjectiveAsync(token);

        await UniTask.Delay(TimeSpan.FromSeconds(pressToFightDelay), ignoreTimeScale: true, cancellationToken: token);

        // ---- Press to Fight を点滅表示しつつ入力を待つ ----
        if (pressToFightText != null)
        {
            // フェードイン
            await pressToFightText.DOFade(1f, 0.3f)
                .SetUpdate(true)
                .SetLink(pressToFightText.gameObject)
                .ToUniTask(cancellationToken: token);

            // 点滅開始
            _blinkCts = new CancellationTokenSource();
            BlinkPressToFightAsync(_blinkCts.Token).Forget();
        }

        // Submit入力を待機
        await WaitForSubmitAsync(token);

        _stopBlinking = true;

        // ---- 入力された → SE再生＆演出終了 ----
        if (introStartSE != null && AudioManager.Instance != null)
        {
            AudioManager.Instance.PlaySE(introStartSE);
        }

        if (stageBGM != null && AudioManager.Instance != null)
        {
            AudioManager.Instance.PlayBGM(stageBGM, 1.0f);
        }

        // 点滅を止める
        _blinkCts?.Cancel();
        _blinkCts?.Dispose();
        _blinkCts = null;

        // 全テキストをフェードアウト
        Sequence fadeOut = DOTween.Sequence();
        if (stageNameText != null) _ = fadeOut.Join(stageNameText.DOFade(0f, 0.3f));
        if (objectiveText != null) _ = fadeOut.Join(objectiveText.DOFade(0f, 0.3f));
        if (pressToFightText != null) _ = fadeOut.Join(pressToFightText.DOFade(0f, 0.3f));
        _ = fadeOut.SetUpdate(true).SetLink(gameObject);
        await fadeOut.ToUniTask(cancellationToken: token);

        // オーバーレイをフェードアウト
        if (introOverlayCanvasGroup != null)
        {
            await introOverlayCanvasGroup.DOFade(0f, 0.3f)
                .SetUpdate(true)
                .SetLink(introOverlayCanvasGroup.gameObject)
                .ToUniTask(cancellationToken: token);
            introOverlayCanvasGroup.interactable = false;
            introOverlayCanvasGroup.blocksRaycasts = false;
            introOverlayCanvasGroup.gameObject.SetActive(false);
        }

        // ゲーム進行を再開
        Time.timeScale = 1f;

        // GameMaster への通知
        if (GameMaster.Instance != null)
        {
            GameMaster.Instance.ChangeState(GameMaster.GameState.Gameplay);
        }

        _isIntroFinished = true;
        OnIntroComplete?.Invoke();
    }

    // =========================================
    // ステージ名アニメーション
    // =========================================

    /// <summary>
    /// ステージ名を大きなスケールから縮小しつつフェードインする「ズームイン」演出。
    /// 画面に叩きつけるような迫力を出す。
    /// </summary>
    private async UniTask ShowStageNameAsync(CancellationToken token)
    {
        if (stageNameText == null) return;

        // SE再生
        if (introStageNameSE != null && AudioManager.Instance != null)
        {
            AudioManager.Instance.PlaySE(introStageNameSE);
        }

        // 初期状態: 大きくて透明
        stageNameText.transform.localScale = Vector3.one * stageNameStartScale;
        SetTextAlpha(stageNameText, 0f);

        // ズームイン（大→通常サイズ）＋ フェードイン を同時実行
        Sequence seq = DOTween.Sequence();
        _ = seq.Join(stageNameText.transform.DOScale(Vector3.one, stageNameDuration).SetEase(stageNameEase));
        _ = seq.Join(stageNameText.DOFade(1f, stageNameDuration * 0.6f)); // 少し早めにフェード完了
        _ = seq.SetUpdate(true).SetLink(stageNameText.gameObject);
        await seq.ToUniTask(cancellationToken: token);

        // パンチスケールで着地の衝撃感
        await stageNameText.transform.DOPunchScale(
            Vector3.one * stageNamePunchStrength, 0.2f, 2, 0.5f
        ).SetUpdate(true)
         .SetLink(stageNameText.gameObject)
         .ToUniTask(cancellationToken: token);
    }

    // =========================================
    // 目標テキストアニメーション
    // =========================================

    /// <summary>
    /// 目標テキストを左から右へスライドしつつフェードインする。
    /// </summary>
    private async UniTask ShowObjectiveAsync(CancellationToken token)
    {
        if (objectiveText == null) return;

        // SE再生
        if (introObjectiveSE != null && AudioManager.Instance != null)
        {
            AudioManager.Instance.PlaySE(introObjectiveSE);
        }

        RectTransform rt = objectiveText.GetComponent<RectTransform>();
        if (rt == null) return;

        // 初期状態: 左にずれて透明
        float originalX = rt.anchoredPosition.x;
        rt.anchoredPosition = new Vector2(originalX - objectiveSlideDistance, rt.anchoredPosition.y);
        SetTextAlpha(objectiveText, 0f);

        // スライドイン＋フェードイン
        Sequence seq = DOTween.Sequence();
        _ = seq.Join(rt.DOAnchorPosX(originalX, objectiveDuration).SetEase(objectiveEase));
        _ = seq.Join(objectiveText.DOFade(1f, objectiveDuration));
        _ = seq.SetUpdate(true).SetLink(objectiveText.gameObject);
        await seq.ToUniTask(cancellationToken: token);
    }

    // =========================================
    // Press to Fight 点滅
    // =========================================
    private async UniTask BlinkPressToFightAsync(CancellationToken token)
    {
        try
        {
            while (!token.IsCancellationRequested && !_stopBlinking)
            {
                if (pressToFightText != null)
                {
                    pressToFightText.alpha = Mathf.PingPong(Time.unscaledTime * blinkSpeed, 1.0f);
                }
                await UniTask.Yield(PlayerLoopTiming.Update, token);
            }
        }
        catch (OperationCanceledException) { }
    }

    // =========================================
    // 入力待ち
    // =========================================

    private async UniTask WaitForSubmitAsync(CancellationToken token)
    {
        if (submitActionRef == null || submitActionRef.action == null) return;

        InputAction submitAction = submitActionRef.action;
        submitAction.Enable();

        _submitPressed = false;
        submitAction.performed += OnSubmitPerformed;

        try
        {
            await UniTask.WaitUntil(() => _submitPressed, cancellationToken: token);
        }
        finally
        {
            submitAction.performed -= OnSubmitPerformed;
        }
    }

    private void OnSubmitPerformed(InputAction.CallbackContext context)
    {
        _submitPressed = true;
    }

    // =========================================
    // ユーティリティ
    // =========================================

    private void SetTextAlpha(TextMeshProUGUI text, float alpha)
    {
        if (text == null) return;
        Color c = text.color;
        c.a = alpha;
        text.color = c;
    }
}
