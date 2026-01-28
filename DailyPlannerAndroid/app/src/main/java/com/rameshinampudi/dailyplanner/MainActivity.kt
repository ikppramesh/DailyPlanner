package com.rameshinampudi.dailyplanner

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rameshinampudi.dailyplanner.ui.theme.DailyPlannerTheme
import com.rameshinampudi.dailyplanner.ui.ContentView

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            DailyPlannerTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val viewModel: PlannerViewModel = viewModel(
                        factory = PlannerViewModelFactory(application)
                    )
                    ContentView(viewModel = viewModel)
                }
            }
        }
    }
}
