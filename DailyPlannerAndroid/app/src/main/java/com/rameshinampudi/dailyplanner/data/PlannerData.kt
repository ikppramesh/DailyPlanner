package com.rameshinampudi.dailyplanner.data

import java.time.LocalDate

data class TaskItem(
    val id: String = java.util.UUID.randomUUID().toString(),
    var text: String = "",
    var isCompleted: Boolean = false
)

data class PriorityItem(
    val number: Int,
    var text: String = ""
)

data class HourlySlot(
    val hour: Int,
    var text: String = ""
) {
    val displayTime: String
        get() {
            val period = if (hour < 12) "AM" else "PM"
            val displayHour = when (hour) {
                0 -> 12
                in 1..12 -> hour
                else -> hour - 12
            }
            return "$displayHour $period"
        }
}

enum class HabitType(val icon: String) {
    WATER("💧"),
    EXERCISE("🏃"),
    MEDITATION("🧘"),
    READING("📚"),
    SLEEP("😴"),
    NUTRITION("🥗"),
    WORK("💼")
}

enum class Mood {
    GREAT, GOOD, OKAY, BAD, TERRIBLE
}

data class DailyPlan(
    val date: LocalDate = LocalDate.now(),
    val tasks: MutableList<TaskItem> = mutableListOf(),
    val priorities: List<PriorityItem> = List(3) { PriorityItem(it + 1) },
    val hourlySlots: List<HourlySlot> = List(24) { HourlySlot(it) },
    val completedHabits: MutableSet<HabitType> = mutableSetOf(),
    var selectedMood: Mood? = null,
    var notes: String? = null
)
