package com.unity3d.player;

import android.os.Bundle;

// Compatibility bridge for plugins that still reference the legacy Activity class name.
public class UnityPlayerActivity extends UnityPlayerGameActivity {
	protected final UnityPlayerActivityBridge mUnityPlayer = new UnityPlayerActivityBridge();

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		mUnityPlayer.setDelegate(super.mUnityPlayer);
	}

	@Override
	protected void onCreateSurfaceView() {
		super.onCreateSurfaceView();
		mUnityPlayer.setDelegate(super.mUnityPlayer);
	}

	// Unity 6 GameActivity player does not expose onTrimMemory like older activity-based APIs.
	// This adapter keeps old plugin calls source-compatible.
	protected static final class UnityPlayerActivityBridge {
		private UnityPlayerForGameActivity delegate;

		void setDelegate(UnityPlayerForGameActivity delegate) {
			this.delegate = delegate;
		}

		public void unload() {
			if (delegate != null) {
				delegate.unload();
			}
		}

		public void destroy() {
			if (delegate != null) {
				delegate.destroy();
			}
		}

		public void pause() {
			if (delegate != null) {
				delegate.pause();
			}
		}

		public void resume() {
			if (delegate != null) {
				delegate.resume();
			}
		}

		public void onTrimMemory(UnityPlayerForActivityOrService.MemoryUsage ignored) {
			// No-op on Unity GameActivity integration.
		}
	}
}
