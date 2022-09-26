package io.github.droidkaigi.confsched2022.feature.setting

import android.os.Build
import android.os.Build.VERSION_CODES
import androidx.annotation.ChecksSdkIntAtLeast
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import app.cash.molecule.AndroidUiDispatcher
import app.cash.molecule.RecompositionClock.ContextClock
import dagger.hilt.android.lifecycle.HiltViewModel
import io.github.droidkaigi.confsched2022.ui.moleculeComposeState
import kotlinx.coroutines.CoroutineScope
import javax.inject.Inject

@HiltViewModel
class SharedSettingViewModel @Inject constructor(
) : ViewModel() {
    private val moleculeScope =
        CoroutineScope(viewModelScope.coroutineContext + AndroidUiDispatcher.Main)

    val uiModel: State<SharedSettingUiModel>
    private val isDynamicColorEnabled: MutableState<Boolean>

    init {
        // TODO: initialize isDynamicColorEnabled
        isDynamicColorEnabled = mutableStateOf(isSupportedDynamicColor())
        uiModel = moleculeScope.moleculeComposeState(clock = ContextClock) {
            SharedSettingUiModel(isDynamicColorEnabled = isDynamicColorEnabled.value)
        }
    }

    fun onDynamicColorToggle() {
        // TODO: change
        isDynamicColorEnabled.value = !isDynamicColorEnabled.value
    }

    @ChecksSdkIntAtLeast(api = VERSION_CODES.S)
    private fun isSupportedDynamicColor(): Boolean {
        return Build.VERSION.SDK_INT >= VERSION_CODES.S
    }
}