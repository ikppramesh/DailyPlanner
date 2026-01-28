package com.rameshinampudi.dailyplanner

import android.app.Application
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider

class PlannerViewModelFactory(private val application: Application) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(PlannerViewModel::class.java)) {
            return PlannerViewModel(application) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
