package com.olivier.bhapticsgodot;

import android.app.Activity;

import com.bhaptics.bhapticsmanger.SdkRequestHandler;
import com.bhaptics.service.SimpleBhapticsDevice;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/** Pont Godot -> bHaptics Player pour Android / Quest (AIDL via bhaptics_manager.aar). */
public class BhapticsGodot extends GodotPlugin {
    private SdkRequestHandler sdk;
    private String appId = "";

    public BhapticsGodot(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "BhapticsGodot";
    }

    /** Renvoie true si bHaptics Player est installé sur le casque. */
    @UsedByGodot
    public boolean init(String id, String apiKey) {
        Activity activity = getActivity();
        if (activity == null) {
            return false;
        }
        if (sdk == null) {
            sdk = new SdkRequestHandler(activity);
        }
        appId = id;
        sdk.initialize(id, apiKey, "");
        return sdk.isBhapticsUser();
    }

    @UsedByGodot
    public boolean is_player_installed() {
        return sdk != null && sdk.isBhapticsUser();
    }

    @UsedByGodot
    public boolean is_vest_connected() {
        if (sdk == null) {
            return false;
        }
        for (SimpleBhapticsDevice d : sdk.getDeviceList()) {
            if (d.getPosition() == 0 && d.isConnected()) {
                return true;
            }
        }
        return false;
    }

    /** position 0 = TactSuit (32 moteurs : 0-15 devant, 16-31 dos), valeurs 0-100. */
    @UsedByGodot
    public int play_motors(int position, int durationMillis, int[] motors) {
        if (sdk == null) {
            return -1;
        }
        return sdk.playMotors(appId, position, durationMillis, motors);
    }

    @UsedByGodot
    public void stop_all() {
        if (sdk != null) {
            sdk.stopAll(appId);
        }
    }

    @Override
    public void onMainDestroy() {
        if (sdk != null) {
            sdk.quit();
            sdk = null;
        }
        super.onMainDestroy();
    }
}
