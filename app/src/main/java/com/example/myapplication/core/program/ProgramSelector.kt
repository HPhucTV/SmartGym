package com.example.myapplication.core.program

import com.example.myapplication.core.model.GoalConfig
import com.example.myapplication.core.model.ProgramTemplate

sealed interface ProgramSelectionResult {
    data class Found(val program: ProgramTemplate) : ProgramSelectionResult

    data object Unsupported : ProgramSelectionResult
}

object ProgramSelector {
    fun select(
        config: GoalConfig,
        programs: List<ProgramTemplate>,
    ): ProgramSelectionResult {
        val matches = programs.filter {
            it.goal == config.goal &&
                it.level == config.level &&
                it.equipmentProfile == config.equipmentProfile
        }
        require(matches.size <= 1) { "Duplicate programs for $config" }
        return matches.singleOrNull()?.let(ProgramSelectionResult::Found)
            ?: ProgramSelectionResult.Unsupported
    }
}
