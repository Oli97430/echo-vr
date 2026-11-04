## Ajoute à l'APK Quest : le plugin BhapticsGodot, l'AAR officiel bHaptics
## et la déclaration <queries> nécessaire pour joindre bHaptics Player (Android 11+).
@tool
extends EditorPlugin

var _export: BhapticsExport


func _enter_tree() -> void:
	_export = BhapticsExport.new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class BhapticsExport extends EditorExportPlugin:
	const PLUGIN_AAR := "bhaptics_godot/bin/bhaptics_godot-release.aar"
	const SDK_AAR := "bhaptics_godot/bin/bhaptics_manager.aar"

	func _get_name() -> String:
		return "BhapticsGodot"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		var libs := PackedStringArray()
		for p in [PLUGIN_AAR, SDK_AAR]:
			if FileAccess.file_exists("res://addons/" + p):
				libs.append(p)
			else:
				push_warning("bHaptics : %s absent, le gilet ne vibrera pas sur Quest" % p)
		return libs

	func _get_android_manifest_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		return "<queries><package android:name=\"com.bhaptics.player\" /></queries>"
