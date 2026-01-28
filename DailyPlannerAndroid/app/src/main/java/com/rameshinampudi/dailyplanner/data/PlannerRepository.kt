package com.rameshinampudi.dailyplanner.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDate

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "planner_data")

class PlannerRepository(private val context: Context) {
    private val gson = Gson()
    
    companion object {
        private val PLANS_KEY = stringPreferencesKey("daily_plans")
    }
    
    val plansFlow: Flow<Map<LocalDate, DailyPlan>> = context.dataStore.data
        .map { preferences ->
            val json = preferences[PLANS_KEY] ?: "{}"
            try {
                val type = object : TypeToken<Map<String, DailyPlanDto>>() {}.type
                val dtoMap: Map<String, DailyPlanDto> = gson.fromJson(json, type)
                dtoMap.mapKeys { LocalDate.parse(it.key) }
                    .mapValues { it.value.toDailyPlan() }
            } catch (e: Exception) {
                emptyMap()
            }
        }
    
    suspend fun savePlans(plans: Map<LocalDate, DailyPlan>) {
        context.dataStore.edit { preferences ->
            val dtoMap = plans.mapKeys { it.key.toString() }
                .mapValues { DailyPlanDto.fromDailyPlan(it.value) }
            val json = gson.toJson(dtoMap)
            preferences[PLANS_KEY] = json
        }
    }
}

// DTOs for serialization
data class TaskItemDto(
    val id: String,
    val text: String,
    val isCompleted: Boolean
)

data class PriorityItemDto(
    val number: Int,
    val text: String
)

data class HourlySlotDto(
    val hour: Int,
    val text: String
)

data class DailyPlanDto(
    val date: String,
    val tasks: List<TaskItemDto>,
    val priorities: List<PriorityItemDto>,
    val hourlySlots: List<HourlySlotDto>,
    val completedHabits: List<String>,
    val selectedMood: String?,
    val notes: String?
) {
    companion object {
        fun fromDailyPlan(plan: DailyPlan): DailyPlanDto {
            return DailyPlanDto(
                date = plan.date.toString(),
                tasks = plan.tasks.map { TaskItemDto(it.id, it.text, it.isCompleted) },
                priorities = plan.priorities.map { PriorityItemDto(it.number, it.text) },
                hourlySlots = plan.hourlySlots.map { HourlySlotDto(it.hour, it.text) },
                completedHabits = plan.completedHabits.map { it.name },
                selectedMood = plan.selectedMood?.name,
                notes = plan.notes
            )
        }
    }
    
    fun toDailyPlan(): DailyPlan {
        return DailyPlan(
            date = LocalDate.parse(date),
            tasks = tasks.map { TaskItem(it.id, it.text, it.isCompleted) }.toMutableList(),
            priorities = priorities.map { PriorityItem(it.number, it.text) },
            hourlySlots = hourlySlots.map { HourlySlot(it.hour, it.text) },
            completedHabits = completedHabits.mapNotNull { 
                try { HabitType.valueOf(it) } catch (e: Exception) { null }
            }.toMutableSet(),
            selectedMood = selectedMood?.let { 
                try { Mood.valueOf(it) } catch (e: Exception) { null }
            },
            notes = notes
        )
    }
}
