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
                
                // Perform rollover on app launch
                performRolloverIfNeeded()
            }
        }
    }
    
    private fun performRolloverIfNeeded() {
        val today = LocalDate.now()
        val prefs = getApplication<Application>().getSharedPreferences("daily_planner", android.content.Context.MODE_PRIVATE)
        val lastRolloverDate = prefs.getString("last_rollover_date", null)?.let { LocalDate.parse(it) }
        
        // Only rollover once per day
        if (lastRolloverDate == null || lastRolloverDate.isBefore(today)) {
            rolloverIncompleteTasks()
            prefs.edit().putString("last_rollover_date", today.toString()).apply()
        }
    }
    
    private fun rolloverIncompleteTasks() {
        val today = LocalDate.now()
        
        // Collect all incomplete tasks from previous dates and deduplicate them
        val uniqueTaskTexts = mutableSetOf<String>()
        val incompleteTasksToRollover = mutableListOf<TaskItem>()
        
        // Iterate through all saved dates
        for ((date, plan) in plans) {
            // Skip today and future dates
            if (!date.isBefore(today)) continue
            
            // Get incomplete tasks with text (non-empty after trimming)
            val incompleteTasks = plan.tasks.filter {
                !it.isCompleted && it.text.trim().isNotEmpty()
            }
            
            // Add only unique tasks (case-insensitive)
            for (task in incompleteTasks) {
                val taskTextLower = task.text.lowercase().trim()
                if (taskTextLower.isNotEmpty() && !uniqueTaskTexts.contains(taskTextLower)) {
                    uniqueTaskTexts.add(taskTextLower)
                    incompleteTasksToRollover.add(task)
                }
            }
        }
        
        // If there are incomplete tasks, add them to today
        if (incompleteTasksToRollover.isNotEmpty()) {
            val todayPlan = plans.getOrPut(today) { DailyPlan(today) }
            
            // Get existing task texts to avoid duplicates
            val existingTaskTexts = todayPlan.tasks.map { 
                it.text.lowercase().trim() 
            }.toSet()
            
            // Add incomplete tasks that don't already exist
            for (task in incompleteTasksToRollover) {
                val taskTextLower = task.text.lowercase().trim()
                if (taskTextLower.isNotEmpty() && !existingTaskTexts.contains(taskTextLower)) {
                    // Create new task with new ID but same text
                    todayPlan.tasks.add(TaskItem(text = task.text, isCompleted = false))
                }
            }
            
            // Save updated plans
            savePlans()
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
