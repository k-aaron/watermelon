extends Node

# 오디오 플레이어들
@onready var bgm_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

# 볼륨 설정
var master_volume: float = 1.0
var bgm_volume: float = 0.7
var sfx_volume: float = 0.8

# 사운드 효과 타입
enum SoundType {
	DROP,       # 과일 드롭
	MERGE,      # 과일 병합
	BOUNCE,     # 벽면 충돌
	GAME_OVER,  # 게임 오버
	BUTTON      # 버튼 클릭
}

func _ready():
	# 오디오 플레이어 설정
	add_child(bgm_player)
	add_child(sfx_player)

	bgm_player.name = "BGMPlayer"
	sfx_player.name = "SFXPlayer"

	# 볼륨 적용
	update_volumes()

func play_sfx(sound_type: SoundType):
	# 현재는 임시로 빈 구현
	# 나중에 실제 사운드 파일과 연결
	print("Playing SFX: ", SoundType.keys()[sound_type])

func play_bgm():
	# 배경음악 재생 (루프)
	if bgm_player.stream:
		bgm_player.play()

func stop_bgm():
	# 배경음악 정지
	bgm_player.stop()

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	update_volumes()

func set_bgm_volume(volume: float):
	bgm_volume = clamp(volume, 0.0, 1.0)
	update_volumes()

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	update_volumes()

func update_volumes():
	if bgm_player:
		bgm_player.volume_db = linear_to_db(master_volume * bgm_volume)
	if sfx_player:
		sfx_player.volume_db = linear_to_db(master_volume * sfx_volume)

func load_audio_settings():
	# 저장된 오디오 설정 로드
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")

	if err == OK:
		master_volume = config.get_value("audio", "master_volume", 1.0)
		bgm_volume = config.get_value("audio", "bgm_volume", 0.7)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
		update_volumes()

func save_audio_settings():
	# 오디오 설정 저장
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save("user://audio_settings.cfg")