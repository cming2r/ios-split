#!/usr/bin/env python3
"""Add es-ES, ja, ko translations to Localizable.xcstrings."""

import json
import collections

INPUT_FILE = "/Users/tuaming/Desktop/type/ios-split/split/Resources/Localizable.xcstrings"

translations = {
    "About": ("Acerca de", "アプリについて", "앱 정보"),
    "Add": ("Añadir", "追加", "추가"),
    "Add Budget": ("Añadir presupuesto", "予算を追加", "예산 추가"),
    "Add Expense": ("Añadir gasto", "支出を追加", "지출 추가"),
    "Add Label": ("Añadir etiqueta", "ラベルを追加", "라벨 추가"),
    "Add Member": ("Añadir miembro", "メンバーを追加", "멤버 추가"),
    "Add Person": ("Añadir persona", "人物を追加", "인원 추가"),
    "Alert Settings": ("Configuración de alertas", "アラート設定", "알림 설정"),
    "Alert threshold: %lld%%": ("Umbral de alerta: %lld%%", "アラート閾値: %lld%%", "알림 임계값: %lld%%"),
    "All": ("Todo", "すべて", "전체"),
    "All accounts are settled": ("Todas las cuentas están saldadas", "すべての精算が完了しました", "모든 정산이 완료되었습니다"),
    "All Countries": ("Todos los países", "すべての国", "모든 국가"),
    "All Settled": ("Todo saldado", "精算済み", "정산 완료"),
    "Almost over budget": ("Casi excedido", "予算超過間近", "예산 초과 임박"),
    "Amount": ("Importe", "金額", "금액"),
    "≈ %@": ("≈ %@", "≈ %@", "≈ %@"),
    "API Server": ("Servidor API", "APIサーバー", "API 서버"),
    "Apply to Category": ("Aplicar a categoría", "カテゴリに適用", "카테고리에 적용"),
    "Avatar": ("Avatar", "アバター", "아바타"),
    "Average": ("Promedio", "平均", "평균"),
    "Back": ("Atrás", "戻る", "뒤로"),
    "Balance Summary": ("Resumen de saldo", "収支サマリー", "잔액 요약"),
    "Base Currency": ("Moneda base", "基準通貨", "기준 통화"),
    "Basic Info": ("Info básica", "基本情報", "기본 정보"),
    "Budget": ("Presupuesto", "予算", "예산"),
    "Set a budget to track your spending": ("Establece un presupuesto para controlar tus gastos", "予算を設定して支出を管理しましょう", "예산을 설정하여 지출을 관리하세요"),
    "Budget Amount": ("Importe del presupuesto", "予算額", "예산 금액"),
    "%@ remaining": ("%@ restante", "残り %@", "%@ 남음"),
    "%1$@ / %2$@": ("%1$@ / %2$@", "%1$@ / %2$@", "%1$@ / %2$@"),
    "Please allow camera access in Settings": ("Permite el acceso a la cámara en Ajustes", "設定でカメラへのアクセスを許可してください", "설정에서 카메라 접근을 허용해 주세요"),
    "Camera Access Required": ("Se requiere acceso a la cámara", "カメラへのアクセスが必要です", "카메라 접근 필요"),
    "Cancel": ("Cancelar", "キャンセル", "취소"),
    "This action cannot be undone": ("Esta acción no se puede deshacer", "この操作は取り消せません", "이 작업은 되돌릴 수 없습니다"),
    "Categories": ("Categorías", "カテゴリ管理", "카테고리 관리"),
    "Category": ("Categoría", "カテゴリ", "카테고리"),
    "Category Name": ("Nombre de categoría", "カテゴリ名", "카테고리 이름"),
    "Change Photo": ("Cambiar foto", "写真を変更", "사진 변경"),
    "Choose from Photos": ("Elegir de fotos", "写真から選択", "사진에서 선택"),
    "Choose Photo": ("Elegir foto", "写真を選択", "사진 선택"),
    "Close": ("Cerrar", "閉じる", "닫기"),
    "Confirm Delete": ("Confirmar eliminación", "削除の確認", "삭제 확인"),
    "Confirm Expense": ("Confirmar gasto", "支出を確認", "지출 확인"),
    "Country": ("País", "国", "국가"),
    "Australia": ("Australia", "オーストラリア", "호주"),
    "Canada": ("Canadá", "カナダ", "캐나다"),
    "China": ("China", "中国", "중국"),
    "Europe": ("Europa", "ヨーロッパ", "유럽"),
    "Hong Kong": ("Hong Kong", "香港", "홍콩"),
    "India": ("India", "インド", "인도"),
    "Indonesia": ("Indonesia", "インドネシア", "인도네시아"),
    "Japan": ("Japón", "日本", "일본"),
    "South Korea": ("Corea del Sur", "韓国", "한국"),
    "Malaysia": ("Malasia", "マレーシア", "말레이시아"),
    "New Zealand": ("Nueva Zelanda", "ニュージーランド", "뉴질랜드"),
    "Philippines": ("Filipinas", "フィリピン", "필리핀"),
    "Singapore": ("Singapur", "シンガポール", "싱가포르"),
    "Taiwan": ("Taiwán", "台湾", "대만"),
    "Thailand": ("Tailandia", "タイ", "태국"),
    "United Kingdom": ("Reino Unido", "イギリス", "영국"),
    "United States": ("Estados Unidos", "アメリカ", "미국"),
    "Vietnam": ("Vietnam", "ベトナム", "베트남"),
    "%@ is not supported": ("%@ no es compatible", "%@ はサポートされていません", "%@은(는) 지원되지 않습니다"),
    "You need to create a trip before scanning receipts": ("Necesitas crear un viaje antes de escanear recibos", "レシートをスキャンするには先に旅行を作成してください", "영수증을 스캔하려면 먼저 여행을 생성하세요"),
    "Create a Trip First": ("Crea un viaje primero", "まず旅行を作成", "먼저 여행을 생성하세요"),
    "Currencies": ("Monedas", "通貨管理", "통화 관리"),
    "Currency": ("Moneda", "通貨", "통화"),
    "Current Rates": ("Tasas actuales", "現在のレート", "현재 환율"),
    "Dad": ("Papá", "パパ", "아빠"),
    "Daily Average": ("Promedio diario", "日平均", "일 평균"),
    "Date": ("Fecha", "日付", "날짜"),
    "Default": ("Por defecto", "デフォルト", "기본"),
    "Delete": ("Eliminar", "削除", "삭제"),
    "Delete this expense?": ("¿Eliminar este gasto?", "この支出を削除しますか？", "이 지출을 삭제하시겠습니까?"),
    "Delete Trip": ("Eliminar viaje", "旅行を削除", "여행 삭제"),
    "Delete \"%@\" and all its expenses?": ("¿Eliminar \"%@\" y todos sus gastos?", "「%@」とすべての支出を削除しますか？", "\"%@\" 및 모든 지출을 삭제하시겠습니까?"),
    "Destination": ("Destino", "目的地", "목적지"),
    "Details": ("Detalles", "詳細", "상세 정보"),
    "Detecting...": ("Detectando...", "検出中...", "감지 중..."),
    "Done": ("Hecho", "完了", "완료"),
    "Edit": ("Editar", "編集", "편집"),
    "Edit Budget": ("Editar presupuesto", "予算を編集", "예산 편집"),
    "Edit Category": ("Editar categoría", "カテゴリを編集", "카테고리 편집"),
    "Edit Expense": ("Editar gasto", "支出を編集", "지출 편집"),
    "Edit Label": ("Editar etiqueta", "ラベルを編集", "라벨 편집"),
    "Edit Member": ("Editar miembro", "メンバーを編集", "멤버 편집"),
    "Edit Person": ("Editar persona", "人物を編集", "인원 편집"),
    "Edit Trip": ("Editar viaje", "旅行を編集", "여행 편집"),
    "Enable Budget Alert": ("Activar alerta de presupuesto", "予算アラートを有効化", "예산 알림 활성화"),
    "End Date": ("Fecha fin", "終了日", "종료일"),
    "Enter a name for this template": ("Introduce un nombre para esta plantilla", "テンプレート名を入力", "템플릿 이름을 입력하세요"),
    "Error": ("Error", "エラー", "오류"),
    "Unable to detect country": ("No se puede detectar el país", "国を検出できません", "국가를 감지할 수 없습니다"),
    "Location detection failed: %@": ("Error de detección de ubicación: %@", "位置検出に失敗: %@", "위치 감지 실패: %@"),
    "Unable to process image": ("No se puede procesar la imagen", "画像を処理できません", "이미지를 처리할 수 없습니다"),
    "Invalid API URL": ("URL de API no válida", "無効なAPI URL", "잘못된 API URL"),
    "Network request failed": ("Error de conexión", "ネットワークリクエスト失敗", "네트워크 요청 실패"),
    "Failed to parse response": ("Error al analizar la respuesta", "レスポンスの解析に失敗", "응답 분석 실패"),
    "Recognition failed: %@": ("Reconocimiento fallido: %@", "認識に失敗: %@", "인식 실패: %@"),
    "Server error (%lld)": ("Error del servidor (%lld)", "サーバーエラー (%lld)", "서버 오류 (%lld)"),
    "Unknown error": ("Error desconocido", "不明なエラー", "알 수 없는 오류"),
    "Update failed: %@": ("Actualización fallida: %@", "更新に失敗: %@", "업데이트 실패: %@"),
    "Exchange Rate": ("Tipo de cambio", "為替レート", "환율"),
    "%1$@ → %2$@": ("%1$@ → %2$@", "%1$@ → %2$@", "%1$@ → %2$@"),
    "Exchange Rates": ("Tipos de cambio", "為替レート設定", "환율 설정"),
    "Expense Details": ("Detalles del gasto", "支出の詳細", "지출 상세"),
    "Expenses": ("Gastos", "支出", "지출"),
    "%lld expenses": ("%lld gastos", "%lld件の支出", "%lld건의 지출"),
    "Tap + to add an expense": ("Toca + para añadir un gasto", "+ をタップして支出を追加", "+ 를 눌러 지출을 추가하세요"),
    "Bug Report": ("Informe de error", "バグ報告", "버그 신고"),
    "Feature Request": ("Solicitud de función", "機能リクエスト", "기능 요청"),
    "Other": ("Otro", "その他", "기타"),
    "Question": ("Pregunta", "質問", "문의"),
    "This action cannot be undone.": ("Esta acción no se puede deshacer.", "この操作は取り消せません。", "이 작업은 되돌릴 수 없습니다."),
    "Delete Feedback?": ("¿Eliminar comentario?", "フィードバックを削除しますか？", "피드백을 삭제하시겠습니까?"),
    "Please describe in detail...": ("Describe en detalle...", "詳細を記述してください...", "자세히 설명해 주세요..."),
    "My Feedback Records": ("Mis registros de comentarios", "フィードバック履歴", "내 피드백 기록"),
    "My Feedbacks": ("Mis comentarios", "フィードバック一覧", "내 피드백"),
    "No feedback records yet": ("Sin registros de comentarios", "フィードバック履歴がありません", "피드백 기록이 없습니다"),
    "Official Reply": ("Respuesta oficial", "公式回答", "공식 답변"),
    "Closed": ("Cerrado", "クローズ", "종료"),
    "Pending": ("Pendiente", "保留中", "대기 중"),
    "Read": ("Leído", "既読", "읽음"),
    "Replied": ("Respondido", "回答済み", "답변 완료"),
    "Subject": ("Asunto", "件名", "제목"),
    "Brief summary": ("Resumen breve", "概要", "간단한 요약"),
    "Submit": ("Enviar", "送信", "제출"),
    "Submit Failed": ("Error al enviar", "送信失敗", "제출 실패"),
    "Submitted Successfully": ("Enviado con éxito", "送信完了", "제출 완료"),
    "Submitting...": ("Enviando...", "送信中...", "제출 중..."),
    "Thank you for your feedback! We'll review it soon.": ("¡Gracias por tus comentarios! Lo revisaremos pronto.", "フィードバックありがとうございます！早急に確認いたします。", "피드백 감사합니다! 빠른 시일 내에 검토하겠습니다."),
    "Feedback": ("Comentarios", "フィードバック", "피드백"),
    "Icon": ("Icono", "アイコン", "아이콘"),
    "%lld images selected": ("%lld imágenes seleccionadas", "%lld枚の画像を選択", "%lld장의 이미지 선택"),
    "Info": ("Info", "情報", "정보"),
    "This is me": ("Soy yo", "自分", "나입니다"),
    "Item": ("Concepto", "品目", "항목"),
    "Label": ("Etiqueta", "ラベル", "라벨"),
    "Group A": ("Grupo A", "グループA", "그룹A"),
    "Group B": ("Grupo B", "グループB", "그룹B"),
    "Just Me": ("Solo yo", "自分のみ", "나만"),
    "Label %lld": ("Etiqueta %lld", "ラベル %lld", "라벨 %lld"),
    "Partner": ("Pareja", "パートナー", "파트너"),
    "Label Name": ("Nombre de etiqueta", "ラベル名", "라벨 이름"),
    "Labels": ("Etiquetas", "ラベル", "라벨"),
    "%lld labels, %lld participants": ("%lld etiquetas, %lld participantes", "%lldラベル、%lld人の参加者", "%lld개 라벨, %lld명 참여자"),
    "Label Templates": ("Plantillas de etiqueta", "ラベルテンプレート", "라벨 템플릿"),
    "Last Updated": ("Última actualización", "最終更新", "최종 업데이트"),
    "• %@": ("• %@", "• %@", "• %@"),
    "Load from Template": ("Cargar desde plantilla", "テンプレートから読み込む", "템플릿에서 불러오기"),
    "Local": ("Local", "ローカル", "로컬"),
    "Manual Entry": ("Entrada manual", "手動入力", "수동 입력"),
    "Me": ("Yo", "自分", "나"),
    "(Me)": ("(Yo)", "(自分)", "(나)"),
    "Name": ("Nombre", "名前", "이름"),
    "Members": ("Miembros", "メンバー", "멤버"),
    "%lld members": ("%lld miembros", "%lld人のメンバー", "%lld명의 멤버"),
    "Tap + to add a member": ("Toca + para añadir un miembro", "+ をタップしてメンバーを追加", "+ 를 눌러 멤버를 추가하세요"),
    "Companion Templates": ("Plantillas de compañeros", "旅行メンバーテンプレート", "여행 동반자 템플릿"),
    "Missing Information": ("Información incompleta", "情報が不足しています", "정보 부족"),
    "Mom": ("Mamá", "ママ", "엄마"),
    "Month": ("Mes", "今月", "이번 달"),
    "More Countries": ("Más países", "その他の国", "더 많은 국가"),
    "Must include \"Me\"": ("Debe incluir \"Yo\"", "「自分」を含める必要があります", "\"나\"를 포함해야 합니다"),
    "My Currency": ("Mi moneda", "自分の通貨", "내 통화"),
    "This is your home currency for expense tracking": ("Esta es tu moneda principal para el registro de gastos", "家計管理に使用する基本通貨です", "지출 관리에 사용하는 기본 통화입니다"),
    "Need More Members": ("Se necesitan más miembros", "メンバーを追加してください", "멤버가 더 필요합니다"),
    "New Category": ("Nueva categoría", "カテゴリを追加", "카테고리 추가"),
    "New Trip": ("Nuevo viaje", "新規旅行", "새 여행"),
    "No Budget": ("Sin presupuesto", "予算なし", "예산 없음"),
    "No Data": ("Sin datos", "データなし", "데이터 없음"),
    "No Expenses": ("Sin gastos", "支出なし", "지출 없음"),
    "No Members": ("Sin miembros", "メンバーなし", "멤버 없음"),
    "No Templates": ("Sin plantillas", "テンプレートなし", "템플릿 없음"),
    "Notes": ("Notas", "メモ", "메모"),
    "No Trips": ("Sin viajes", "旅行なし", "여행 없음"),
    "Not specified": ("No especificado", "未指定", "미지정"),
    "OK": ("Aceptar", "OK", "확인"),
    "Open Camera": ("Abrir cámara", "カメラを開く", "카메라 열기"),
    "Open Settings": ("Abrir ajustes", "設定を開く", "설정 열기"),
    "Over budget by %@": ("Excedido en %@", "%@ 超過", "%@ 초과"),
    "Paid: %@": ("Pagado: %@", "支払済み: %@", "지불: %@"),
    "Paid By": ("Pagado por", "支払者", "지불한 사람"),
    "%1$@ %2$@": ("%1$@ %2$@", "%1$@ %2$@", "%1$@ %2$@"),
    "Friend A": ("Amigo A", "友人A", "친구A"),
    "Friend B": ("Amigo B", "友人B", "친구B"),
    "P%lld": ("P%lld", "メンバー%lld", "멤버%lld"),
    "%lld people": ("%lld personas", "%lld人", "%lld명"),
    "Participant Name": ("Nombre", "名前", "이름"),
    "Participants": ("Participantes", "参加者", "참여자"),
    "%lld participants": ("%lld participantes", "%lld人の参加者", "%lld명 참여자"),
    "• %lld people": ("• %lld personas", "• %lld人", "• %lld명"),
    "Per Person": ("Por persona", "一人あたり", "1인당"),
    "%@ per person": ("%@ por persona", "一人あたり %@", "1인당 %@"),
    "People": ("Personas", "人物", "인원"),
    "Please enter: ": ("Por favor, introduzca: ", "入力してください: ", "입력해 주세요: "),
    "Popular": ("Populares", "人気", "인기"),
    "Progress: %1$lld/%2$lld": ("Progreso: %1$lld/%2$lld", "進捗: %1$lld/%2$lld", "진행: %1$lld/%2$lld"),
    "Qty: %lld": ("Cant.: %lld", "数量: %lld", "수량: %lld"),
    "Quick add expense": ("Añadir gasto rápido", "支出をすぐに追加", "빠른 지출 추가"),
    "Take photo or select image": ("Tomar foto o seleccionar imagen", "写真を撮るか画像を選択", "사진 촬영 또는 이미지 선택"),
    "Receipt Photo": ("Foto del recibo", "レシート写真", "영수증 사진"),
    "Receipt Scan": ("Escanear recibo", "レシートスキャン", "영수증 스캔"),
    "Recognizing...": ("Reconociendo...", "認識中...", "인식 중..."),
    "Recognizing %lld images...": ("%lld imágenes reconociendo...", "%lld枚の画像を認識中...", "%lld장의 이미지 인식 중..."),
    "Remote": ("Remoto", "リモート", "원격"),
    "Remove Photo": ("Eliminar foto", "写真を削除", "사진 삭제"),
    "Save": ("Guardar", "保存", "저장"),
    "Save as Template": ("Guardar como plantilla", "テンプレートとして保存", "템플릿으로 저장"),
    "Items": ("Artículos", "明細", "명세"),
    "Scanning image %lld": ("Escaneando imagen %lld", "画像 %lld をスキャン中", "이미지 %lld 스캔 중"),
    "Scan Receipt": ("Escanear recibo", "レシートをスキャン", "영수증 스캔"),
    "Search country or currency": ("Buscar país o moneda", "国または通貨を検索", "국가 또는 통화 검색"),
    "Search trips": ("Buscar viajes", "旅行を検索", "여행 검색"),
    "Select Category": ("Seleccionar categoría", "カテゴリを選択", "카테고리 선택"),
    "Select Country": ("Seleccionar país", "国を選択", "국가 선택"),
    "Select from Map": ("Seleccionar en el mapa", "地図から選択", "지도에서 선택"),
    "Select Template": ("Seleccionar plantilla", "テンプレートを選択", "템플릿 선택"),
    "Select This Country": ("Seleccionar este país", "この国を選択", "이 국가 선택"),
    "Select a trip": ("Seleccionar un viaje", "旅行を選択", "여행 선택"),
    "Select Trip": ("Seleccionar viaje", "旅行を選択", "여행 선택"),
    "Settlement": ("Liquidación", "精算", "정산"),
    "At least 2 members are required for settlement": ("Se necesitan al menos 2 miembros para liquidar", "精算には2名以上のメンバーが必要です", "정산하려면 최소 2명의 멤버가 필요합니다"),
    "Add expenses to see settlement": ("Añade gastos para ver la liquidación", "支出を追加すると精算を確認できます", "지출을 추가하면 정산을 확인할 수 있습니다"),
    "Source": ("Origen", "ソース", "출처"),
    "Split Details": ("Detalles de la división", "割り勘の詳細", "분할 상세"),
    "Split Labels": ("Etiquetas de división", "割り勘ラベル", "분할 라벨"),
    "Split with: %@": ("Dividir con: %@", "割り勘対象: %@", "분할 대상: %@"),
    "Split With": ("Dividir con", "割り勘対象", "분할 대상"),
    "Start Date": ("Fecha inicio", "開始日", "시작일"),
    "Start Scan": ("Iniciar escaneo", "スキャン開始", "스캔 시작"),
    "Suggested Settlements": ("Liquidaciones sugeridas", "おすすめの精算方法", "추천 정산 방법"),
    "Scan": ("Escanear", "スキャン", "스캔"),
    "Settings": ("Ajustes", "設定", "설정"),
    "Trips": ("Viajes", "旅行", "여행"),
    "Tags": ("Etiquetas", "タグ", "태그"),
    "Take Photo": ("Tomar foto", "写真を撮る", "사진 촬영"),
    "Tap on the map to select a country": ("Toca el mapa para seleccionar un país", "地図をタップして国を選択", "지도를 탭하여 국가를 선택하세요"),
    "Couple Trip": ("Viaje en pareja", "カップル旅行", "커플 여행"),
    "Solo Trip": ("Viaje en solitario", "ひとり旅", "혼자 여행"),
    "Family Trip": ("Viaje familiar", "家族旅行", "가족 여행"),
    "Template Name": ("Nombre de plantilla", "テンプレート名", "템플릿 이름"),
    "Templates": ("Plantillas", "テンプレート", "템플릿"),
    "Templates will appear here when you save label groups from trips": ("Las plantillas aparecerán aquí cuando guardes grupos de etiquetas de viajes", "旅行からラベルグループを保存すると、ここにテンプレートが表示されます", "여행에서 라벨 그룹을 저장하면 여기에 템플릿이 표시됩니다"),
    "Time": ("Hora", "時刻", "시간"),
    "Time Zone": ("Zona horaria", "タイムゾーン", "시간대"),
    "To Pay": ("A pagar", "支払い", "지불할 금액"),
    "To Receive": ("A recibir", "受け取り", "받을 금액"),
    "Total Budget": ("Presupuesto total", "総予算", "총 예산"),
    "Total Budget (All Categories)": ("Presupuesto total (todas las categorías)", "総予算（全カテゴリ）", "총 예산 (전체 카테고리)"),
    "Total Expenses": ("Gastos totales", "総支出", "총 지출"),
    "Travel Companions": ("Compañeros de viaje", "旅行メンバー", "여행 동반자"),
    "Trip Name": ("Nombre del viaje", "旅行名", "여행 이름"),
    "Tap the + button in the top right to create your first trip": ("Toca el botón + en la esquina superior derecha para crear tu primer viaje", "右上の + ボタンをタップして最初の旅行を作成しましょう", "오른쪽 상단의 + 버튼을 눌러 첫 여행을 만드세요"),
    "Uncategorized": ("Sin categoría", "未分類", "미분류"),
    "Update Rates": ("Actualizar tasas", "レートを更新", "환율 업데이트"),
    "Version": ("Versión", "バージョン", "버전"),
    "Week": ("Semana", "今週", "이번 주"),
    "No expenses in this category": ("Sin gastos en esta categoría", "このカテゴリの支出はありません", "이 카테고리에 지출이 없습니다"),
    "No expenses match this category filter": ("No hay gastos que coincidan con este filtro", "このカテゴリフィルターに一致する支出がありません", "이 카테고리 필터와 일치하는 지출이 없습니다"),
}


def sort_dict_keys(d):
    """Recursively sort dictionary keys."""
    if isinstance(d, dict):
        return collections.OrderedDict(
            (k, sort_dict_keys(v)) for k, v in sorted(d.items())
        )
    return d


def main():
    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        data = json.load(f, object_pairs_hook=collections.OrderedDict)

    matched = 0
    skipped = 0

    for key, entry in data.get("strings", {}).items():
        localizations = entry.get("localizations")
        if not localizations:
            continue
        en_loc = localizations.get("en")
        if not en_loc:
            continue

        # Get the en value
        string_unit = en_loc.get("stringUnit")
        if not string_unit:
            continue
        en_value = string_unit.get("value")
        if en_value is None:
            continue

        # Look up in translations dict
        if en_value not in translations:
            skipped += 1
            continue

        es_val, ja_val, ko_val = translations[en_value]
        matched += 1

        # Add translations
        for lang_code, trans_val in [("es-ES", es_val), ("ja", ja_val), ("ko", ko_val)]:
            localizations[lang_code] = collections.OrderedDict([
                ("stringUnit", collections.OrderedDict([
                    ("state", "translated"),
                    ("value", trans_val),
                ]))
            ])

        # Sort localizations by language code
        entry["localizations"] = collections.OrderedDict(
            (k, localizations[k]) for k in sorted(localizations.keys())
        )

    print(f"Matched and translated: {matched}")
    print(f"Skipped (en value not in dict): {skipped}")

    # Write back with 2-space indent and " : " separators
    with open(INPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2, separators=(" : ", " : "))
        # The original xcstrings files typically don't have separators like that.
        # Actually, looking at the file, the format uses "key" : "value" with spaces around colon.
        # json.dump separators param: (item_separator, key_separator)
        # Default is (', ', ': '). We need (',\n', ' : ') but indent handles newlines.
        # Let me re-check: with indent=2, json.dump already handles newlines.
        # The separator we need is " : " for key-value (with spaces around colon).

    # Actually, json.dump with indent already adds newlines between items.
    # But the separators parameter with indent uses different defaults.
    # With indent != None, default separators are (',', ': ').
    # We want ' : ' instead of ': '.
    # Let me rewrite properly.

    # Rewrite with correct separators
    with open(INPUT_FILE, "w", encoding="utf-8") as f:
        output = json.dumps(data, ensure_ascii=False, indent=2)
        # Replace ": " with " : " for key-value separators
        # But we need to be careful - ": " inside string values should not be changed.
        # Actually, looking at the original file format, the separator is " : " everywhere.
        # The safest approach: use a custom encoder or post-process.
        # Let's use a line-by-line approach.

    # Better approach: write with custom separators
    # json.dumps with indent=2 produces lines like:
    #   "key": "value"
    # We want:
    #   "key" : "value"
    # Also for nested:
    #   "key": {
    # We want:
    #   "key" : {

    import re

    output = json.dumps(data, ensure_ascii=False, indent=2)

    # Replace ": " that appears after a quoted key with " : "
    # Pattern: a quote, then colon, then space -> replace colon-space with space-colon-space
    # But only when it's a JSON key-value separator (after closing quote of a key)
    lines = output.split('\n')
    result_lines = []
    for line in lines:
        # Match pattern: "key": value  (where key ends with ")
        # Replace '": ' with '" : '
        new_line = re.sub(r'": ', '" : ', line)
        result_lines.append(new_line)

    final_output = '\n'.join(result_lines)

    with open(INPUT_FILE, "w", encoding="utf-8") as f:
        f.write(final_output)
        f.write('\n')  # trailing newline

    print("File written successfully.")


if __name__ == "__main__":
    main()
