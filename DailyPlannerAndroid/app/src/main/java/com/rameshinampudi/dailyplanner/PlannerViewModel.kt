package com.rameshinampudi.dailyplanner

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.rameshinampudi.dailyplanner.data.*
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale

class PlannerViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = PlannerRepository(application)
    
    var selectedDate by mutableStateOf(LocalDate.now())
        private set
    
    private val plans = mutableMapOf<LocalDate, DailyPlan>()
    
    init {
        // Load saved plans
        viewModelScope.launch {
            repository.plansFlow.collect { savedPlans ->
                plans.clear()
                plans.putAll(savedPlans)
            }
        }
    }
    
    val currentPlan: DailyPlan
        get() = plans.getOrPut(selectedDate) { DailyPlan(selectedDate) }
    
    val dayOfWeek: String
        get() = selectedDate.dayOfWeek.getDisplayName(TextStyle.FULL, Locale.getDefault())
    
    val selectedDay: Int
        get() = selectedDate.dayOfMonth
    
    val monthName: String
        get() = selectedDate.month.getDisplayName(TextStyle.FULL, Locale.getDefault())
    
    val selectedYear: Int
        get() = selectedDate.year
    
    fun selectDate(date: LocalDate) {
        savePlans()
        selectedDate = date
    }
    
    fun addTask() {
        currentPlan.tasks.add(TaskItem())
        savePlans()
    }
    
    fun toggleTask(index: Int) {
        if (index < currentPlan.tasks.size) {
            currentPlan.tasks[index].isCompleted = !currentPlan.tasks[index].isCompleted
            savePlans()
        }
    }
    
    fun deleteTask(index: Int) {
        if (index < currentPlan.tasks.size) {
            currentPlan.tasks.removeAt(index)
            savePlans()
        }
    }
    
    fun toggleHabit(habit: HabitType) {
        if (currentPlan.completedHabits.contains(habit)) {
            currentPlan.completedHabits.remove(habit)
        } else {
            currentPlan.completedHabits.add(habit)
        }
        savePlans()
    }
    
    fun selectMood(mood: Mood) {
        currentPlan.selectedMood = mood
        savePlans()
    }
    
    fun updateNotes(notes: String) {
        currentPlan.notes = notes
        savePlans()
    }
    
    private fun savePlans() {
        viewModelScope.launch {
            repository.savePlans(plans)
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        savePlans()
    }
}
