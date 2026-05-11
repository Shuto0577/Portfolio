using UnityEngine;
using UnityEngine.SceneManagement;
using Cysharp.Threading.Tasks;
using System;
using System.Threading;
using TMPro;
using DG.Tweening;

/// <summary>
/// リザルト画面の全制御。各ステージシーンに配置する。
/// BattleManager からクリアシーケンス完了後に呼ばれ、
/// テキスト・クリアタイム・ボタンを順番にアニメーション表示する。
///
/// ArcadeMode: クリア → スローモーション → 即リザルト表示
/// StoryMode:  クリア → スローモーション → イベント(未実装) → リザルト表示
/// </summary>
public class ResultController : MonoBehaviour
{
    // =========================================
    // Inspector設定
    // =========================================

    [Header("リザルトパネル全体")]
    [SerializeField] private CanvasGroup resultPanelCanvasGroup;

    [Header("テキスト要素（順番にアニメーション表示）")]
    [Tooltip("「STAGE CLEAR」等のクリアテキスト")]
    [SerializeField] private TextMeshProUGUI clearTitleText;
    [Tooltip("クリアタイムのラベル（例: Clear Time）")]
    [SerializeField] private TextMeshProUGUI clearTimeLabelText;
    [Tooltip("クリアタイムの数値表示")]
    [SerializeField] private TextMeshProUGUI clearTimeValueText;
    [Tooltip("難易度の表示場所")]
    [SerializeField] private TextMeshProUGUI difficultyText;

    [Header("ボタンパネル")]
    [SerializeField] private CanvasGroup buttonPanelCanvasGroup;
    [SerializeField] private GameObject firstResultButton; // Restartボタン

    [Header("アニメーション設定")]
    [SerializeField] private float elementInterval = 0.4f;       // 各要素の表示間隔
    [SerializeField] private float textFadeDuration = 0.3f;      // テキストフェード時間
    [SerializeField] private float textScalePunch = 0.15f;       // テキスト出現時のパンチスケール
    [SerializeField] private float buttonFadeDuration = 0.3f;    // ボタンパネルフェード時間

    [Header("クリアタイム管理")]
    [Tooltip("ステージ開始からの経過時間を自動計測する")]
    [SerializeField] private bool autoTrackTime = true;

    // =========================================
    // 内部状態
    // =========================================

    private CancellationTokenSource _cts;
    private bool _isShowing = false;
    private float _stageStartTime;
    private float _clearTime;

    /// <summary>リザルト画面表示中かどうか</summary>
    public bool IsShowing => _isShowing;

    // =========================================
    // 初期化
    // =========================================

    private void Awake()
    {
        _cts = new CancellationTokenSource();

        // リザルトパネル全体を非表示
        if (resultPanelCanvasGroup != null)
        {
            resultPanelCanvasGroup.alpha = 0f;
            resultPanelCanvasGroup.interactable = false;
            resultPanelCanvasGroup.blocksRaycasts = false;
            resultPanelCanvasGroup.gameObject.SetActive(false);
        }

        // 各テキスト要素を非表示
        SetTextAlpha(clearTitleText, 0f);
        SetTextAlpha(clearTimeLabelText, 0f);
        SetTextAlpha(clearTimeValueText, 0f);

        // ボタンパネルを非表示
        if (buttonPanelCanvasGroup != null)
        {
            buttonPanelCanvasGroup.alpha = 0f;
            buttonPanelCanvasGroup.interactable = false;
            buttonPanelCanvasGroup.blocksRaycasts = false;
        }
    }

    private void Start()
    {
        // クリアタイム計測開始
        if (autoTrackTime)
        {
            _stageStartTime = Time.time;
        }
    }

    private void OnDestroy()
    {
        _cts?.Cancel();
        _cts?.Dispose();
    }

    // =========================================
    // 外部から呼ばれるAPI
    // =========================================

    /// <summary>
    /// リザルト画面を表示する。BattleManager のクリアシーケンス完了後に呼ぶ。
    /// ArcadeMode の場合は直接呼ぶ。StoryMode の場合はイベント終了後に呼ぶ。
    /// </summary>
    public void ShowResult()
    {
        if (_isShowing) return;
        _isShowing = true;

        // クリアタイムを確定
        _clearTime = Time.time - _stageStartTime;

        ShowResultSequenceAsync(_cts.Token).Forget();
    }

    /// <summary>
    /// クリアタイムを外部から明示的に設定する場合に使用する。
    /// autoTrackTime = false の場合に使う想定。
    /// </summary>
    public void SetClearTime(float time)
    {
        _clearTime = time;
    }

    // =========================================
    // リザルト表示シーケンス
    // =========================================

    private async UniTask ShowResultSequenceAsync(CancellationToken token)
    {
        // GameMaster への通知
        if (GameMaster.Instance != null)
        {
            GameMaster.Instance.ChangeState(GameMaster.GameState.Result);
        }

        // パネル全体をアクティブにする（まだ透明）
        if (resultPanelCanvasGroup != null)
        {
            resultPanelCanvasGroup.gameObject.SetActive(true);
            await resultPanelCanvasGroup.DOFade(1f, textFadeDuration)
                .SetUpdate(true)
                .SetLink(resultPanelCanvasGroup.gameObject)
                .ToUniTask(cancellationToken: token);
        }

        // 1. クリアテキストを表示
        await ShowTextWithPunchAsync(clearTitleText, token);
        await UniTask.Delay(TimeSpan.FromSeconds(elementInterval), ignoreTimeScale: true, cancellationToken: token);

        // 2. クリアタイムラベルを表示
        await ShowTextWithPunchAsync(clearTimeLabelText, token);

        // 3. クリアタイム数値をカウントアップ表示
        if (clearTimeValueText != null)
        {
            await ShowTimeCountUpAsync(clearTimeValueText, _clearTime, token);
        }
        await UniTask.Delay(TimeSpan.FromSeconds(elementInterval), ignoreTimeScale: true, cancellationToken: token);

        // 4. ボタンパネルをフェードイン
        if (buttonPanelCanvasGroup != null)
        {
            await buttonPanelCanvasGroup.DOFade(1f, buttonFadeDuration)
                .SetUpdate(true)
                .SetLink(buttonPanelCanvasGroup.gameObject)
                .ToUniTask(cancellationToken: token);
            buttonPanelCanvasGroup.interactable = true;
            buttonPanelCanvasGroup.blocksRaycasts = true;
        }

        // パネル全体のレイキャストをForceSelect前に有効化
        // 親CanvasGroupがinteractable=falseのままだとOnSelectが発火せずScaleGlowが動かない
        if (resultPanelCanvasGroup != null)
        {
            resultPanelCanvasGroup.interactable = true;
            resultPanelCanvasGroup.blocksRaycasts = true;
        }

        // 最初のボタンにフォーカス
        await ForceSelectButtonAsync(firstResultButton, token);
    }

    // =========================================
    // テキストアニメーション
    // =========================================

    /// <summary>テキストをフェードイン＋パンチスケールで表示</summary>
    private async UniTask ShowTextWithPunchAsync(TextMeshProUGUI text, CancellationToken token)
    {
        if (text == null) return;

        text.transform.localScale = Vector3.one;

        // フェードインとパンチスケールを同時実行
        Sequence seq = DOTween.Sequence();
        _ = seq.Join(text.DOFade(1f, textFadeDuration));
        _ = seq.Join(text.transform.DOPunchScale(Vector3.one * textScalePunch, textFadeDuration, 1, 0.5f));
        _ = seq.SetUpdate(true).SetLink(text.gameObject);
        await seq.ToUniTask(cancellationToken: token);
    }

    /// <summary>クリアタイムをカウントアップ演出で表示</summary>
    private async UniTask ShowTimeCountUpAsync(TextMeshProUGUI text, float targetTime, CancellationToken token)
    {
        if (text == null) return;

        // まずフェードイン
        text.alpha = 0f;
        await text.DOFade(1f, textFadeDuration * 0.5f)
            .SetUpdate(true)
            .SetLink(text.gameObject)
            .ToUniTask(cancellationToken: token);

        // カウントアップ演出
        float countUpDuration = 1.0f;
        float elapsed = 0f;

        while (elapsed < countUpDuration)
        {
            elapsed += Time.unscaledDeltaTime;
            float t = Mathf.Clamp01(elapsed / countUpDuration);
            // イージング（OutQuart）で自然なカウントアップ
            float easedT = 1f - Mathf.Pow(1f - t, 4f);
            float displayTime = targetTime * easedT;
            text.text = FormatTime(displayTime);
            await UniTask.Yield(PlayerLoopTiming.Update, token);
        }

        // 最終値を確定
        text.text = FormatTime(targetTime);

        // パンチスケールで強調
        await text.transform.DOPunchScale(Vector3.one * textScalePunch, 0.2f, 1, 0.5f)
            .SetUpdate(true)
            .SetLink(text.gameObject)
            .ToUniTask(cancellationToken: token);
    }

    private string FormatTime(float timeInSeconds)
    {
        int minutes = Mathf.FloorToInt(timeInSeconds / 60f);
        int seconds = Mathf.FloorToInt(timeInSeconds % 60f);
        int milliseconds = Mathf.FloorToInt((timeInSeconds * 100f) % 100f);
        return $"{minutes:00}:{seconds:00}.{milliseconds:00}";
    }

    // =========================================
    // ボタンコールバック（Inspectorから設定）
    // =========================================

    /// <summary>Restartボタン: 同じステージをやり直す</summary>
    public void OnRestartPressed()
    {
        PlaySubmitSE();
        Time.timeScale = 1f;

        var gm = GameMaster.Instance;
        if (gm != null)
            gm.LoadSceneAsync(gm.CurrentSceneName);
        else
            Debug.LogError("[ResultController] GameMaster が存在しないため Restart できません。");

        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.StopAllSounds();
        }
    }

    /// <summary>Back to Titleボタン: タイトル画面へ戻る</summary>
    public void OnBackToTitlePressed()
    {
        PlaySubmitSE();
        Time.timeScale = 1f;

        if (GameMaster.Instance != null)
        {
            GameMaster.Instance.RequestSkipTitleAnimation();  // タイトルショートカット要求を送る
            GameMaster.Instance.LoadSceneAsync("Title");
        }
        else
        {
            SceneManager.LoadScene("Title");
        }

        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.StopAllSounds();
        }
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

    private async UniTask ForceSelectButtonAsync(GameObject button, CancellationToken token)
    {
        if (UINavigationHelper.Instance != null)
            await UINavigationHelper.Instance.ForceSelectAsync(button, token);
    }

    private void PlaySubmitSE()
    {
        if (UISelectSFX.Instance != null)
            UISelectSFX.Instance.PlaySubmitSE();
    }
}
