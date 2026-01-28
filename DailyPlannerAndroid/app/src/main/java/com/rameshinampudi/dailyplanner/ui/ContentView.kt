package com.rameshinampudi.dailyplanner.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.rameshinampudi.dailyplanner.PlannerViewModel
import com.rameshinampudi.dailyplanner.data.*
import java.time.LocalDate
import java.time.YearMonth

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ContentView(viewModel: PlannerViewModel) {
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("Tasks", "Schedule", "Habits", "Mood", "Notes")
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "${viewModel.dayOfWeek}, ${viewModel.monthName} ${viewModel.selectedDay}",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "${viewModel.selectedYear}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                actions = {
                    var showDatePicker by remember { mutableStateOf(false) }
                    IconButton(onClick = { showDatePicker = true }) {
                        Icon(Icons.Default.CalendarToday, contentDescription = "Select Date")
                    }
                    
                    if (showDatePicker) {
                        DatePickerDialog(
                            onDismiss = { showDatePicker = false },
                            onDateSelected = { date ->
                                viewModel.selectDate(date)
                                showDatePicker = false
                            },
                            selectedDate = viewModel.selectedDate
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Tab Row
            ScrollableTabRow(
                selectedTabIndex = selectedTab,
                modifier = Modifier.fillMaxWidth()
            ) {
                tabs.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        text = { Text(title) }
                    )
                }
            }
            
            // Content for selected tab
            when (selectedTab) {
                0 -> TasksView(viewModel)
                1 -> ScheduleView(viewModel)
                2 -> HabitsView(viewModel)
                3 -> MoodView(viewModel)
                4 -> NotesView(viewModel)
            }
        }
    }
}

@Composable
fun DatePickerDialog(
    onDismiss: () -> Unit,
    onDateSelected: (LocalDate) -> Unit,
    selectedDate: LocalDate
) {
    var currentMonth by remember { mutableStateOf(YearMonth.from(selectedDate)) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = { currentMonth = currentMonth.minusMonths(1) }) {
                    Icon(Icons.Default.ChevronLeft, "Previous month")
                }
                Text("${currentMonth.month.name} ${currentMonth.year}")
                IconButton(onClick = { currentMonth = currentMonth.plusMonths(1) }) {
                    Icon(Icons.Default.ChevronRight, "Next month")
                }
            }
        },
        text = {
            CalendarGrid(
                yearMonth = currentMonth,
                selectedDate = selectedDate,
                onDateSelected = onDateSelected
            )
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
fun CalendarGrid(
    yearMonth: YearMonth,
    selectedDate: LocalDate,
    onDateSelected: (LocalDate) -> Unit
) {
    val firstDayOfMonth = yearMonth.atDay(1)
    val daysInMonth = yearMonth.lengthOfMonth()
    val firstDayOfWeek = firstDayOfMonth.dayOfWeek.value % 7
    
    Column {
        // Days of week header
        Row(modifier = Modifier.fillMaxWidth()) {
            listOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat").forEach { day ->
                Text(
                    text = day,
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Bold
                )
            }
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Calendar grid
        var dayCounter = 1
        for (week in 0..5) {
            if (dayCounter > daysInMonth) break
            
            Row(modifier = Modifier.fillMaxWidth()) {
                for (dayOfWeek in 0..6) {
                    if (week == 0 && dayOfWeek < firstDayOfWeek || dayCounter > daysInMonth) {
                        Spacer(modifier = Modifier.weight(1f))
                    } else {
                        val day = dayCounter
                        val date = yearMonth.atDay(day)
                        val isSelected = date == selectedDate
                        val isToday = date == LocalDate.now()
                        
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .aspectRatio(1f)
                                .padding(2.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(
                                    when {
                                        isSelected -> MaterialTheme.colorScheme.primary
                                        isToday -> MaterialTheme.colorScheme.primaryContainer
                                        else -> Color.Transparent
                                    }
                                )
                                .clickable { onDateSelected(date) },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "$day",
                                color = when {
                                    isSelected -> MaterialTheme.colorScheme.onPrimary
                                    isToday -> MaterialTheme.colorScheme.onPrimaryContainer
                                    else -> MaterialTheme.colorScheme.onSurface
                                },
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                        dayCounter++
                    }
                }
            }
        }
    }
}

@Composable
fun TasksView(viewModel: PlannerViewModel) {
    val plan = viewModel.currentPlan
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Top 3 Priorities Section
        Text(
            text = "Top 3 Priorities",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        plan.priorities.forEach { priority ->
            var priorityText by remember { mutableStateOf(priority.text) }
            
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                )
            ) {
                Row(
                    modifier = Modifier.padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "${priority.number}.",
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        modifier = Modifier.padding(end = 8.dp)
                    )
                    TextField(
                        value = priorityText,
                        onValueChange = {
                            priorityText = it
                            priority.text = it
                        },
                        placeholder = { Text("Priority ${priority.number}") },
                        modifier = Modifier.fillMaxWidth(),
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = Color.Transparent,
                            unfocusedContainerColor = Color.Transparent,
                            disabledContainerColor = Color.Transparent,
                        )
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Tasks Section
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Tasks",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            IconButton(onClick = { viewModel.addTask() }) {
                Icon(Icons.Default.Add, contentDescription = "Add Task")
            }
        }
        
        LazyColumn(
            modifier = Modifier.fillMaxSize()
        ) {
            itemsIndexed(plan.tasks) { index, task ->
                var taskText by remember { mutableStateOf(task.text) }
                
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .padding(8.dp)
                            .fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Checkbox(
                            checked = task.isCompleted,
                            onCheckedChange = { viewModel.toggleTask(index) }
                        )
                        
                        TextField(
                            value = taskText,
                            onValueChange = {
                                taskText = it
                                task.text = it
                            },
                            placeholder = { Text("Task description") },
                            modifier = Modifier.weight(1f),
                            textStyle = LocalTextStyle.current.copy(
                                textDecoration = if (task.isCompleted) 
                                    TextDecoration.LineThrough 
                                else 
                                    null
                            ),
                            colors = TextFieldDefaults.colors(
                                focusedContainerColor = Color.Transparent,
                                unfocusedContainerColor = Color.Transparent,
                                disabledContainerColor = Color.Transparent,
                            )
                        )
                        
                        IconButton(onClick = { viewModel.deleteTask(index) }) {
                            Icon(
                                Icons.Default.Delete,
                                contentDescription = "Delete Task",
                                tint = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ScheduleView(viewModel: PlannerViewModel) {
    val plan = viewModel.currentPlan
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            text = "Hourly Schedule",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        LazyColumn {
            itemsIndexed(plan.hourlySlots) { _, slot ->
                var slotText by remember { mutableStateOf(slot.text) }
                
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .padding(12.dp)
                            .fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = slot.displayTime,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.width(70.dp),
                            fontSize = 14.sp
                        )
                        
                        TextField(
                            value = slotText,
                            onValueChange = {
                                slotText = it
                                slot.text = it
                            },
                            placeholder = { Text("Schedule for ${slot.displayTime}") },
                            modifier = Modifier.fillMaxWidth(),
                            colors = TextFieldDefaults.colors(
                                focusedContainerColor = Color.Transparent,
                                unfocusedContainerColor = Color.Transparent,
                                disabledContainerColor = Color.Transparent,
                            )
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun HabitsView(viewModel: PlannerViewModel) {
    val plan = viewModel.currentPlan
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            text = "Daily Habits",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 16.dp)
        )
        
        HabitType.values().forEach { habit ->
            val isCompleted = plan.completedHabits.contains(habit)
            
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
                    .clickable { viewModel.toggleHabit(habit) },
                colors = CardDefaults.cardColors(
                    containerColor = if (isCompleted)
                        MaterialTheme.colorScheme.primaryContainer
                    else
                        MaterialTheme.colorScheme.surface
                )
            ) {
                Row(
                    modifier = Modifier
                        .padding(16.dp)
                        .fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = habit.icon,
                            fontSize = 32.sp,
                            modifier = Modifier.padding(end = 16.dp)
                        )
                        Text(
                            text = habit.name.replace("_", " ").lowercase()
                                .replaceFirstChar { it.uppercase() },
                            style = MaterialTheme.typography.titleMedium
                        )
                    }
                    
                    if (isCompleted) {
                        Icon(
                            Icons.Default.CheckCircle,
                            contentDescription = "Completed",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Summary
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.tertiaryContainer
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Habits Completed",
                    style = MaterialTheme.typography.titleSmall
                )
                Text(
                    text = "${plan.completedHabits.size} / ${HabitType.values().size}",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

@Composable
fun MoodView(viewModel: PlannerViewModel) {
    val plan = viewModel.currentPlan
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            text = "How are you feeling today?",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 24.dp)
        )
        
        data class MoodItem(val mood: Mood, val emoji: String, val label: String)
        
        val moods = listOf(
            MoodItem(Mood.GREAT, "😄", "Great"),
            MoodItem(Mood.GOOD, "🙂", "Good"),
            MoodItem(Mood.OKAY, "😐", "Okay"),
            MoodItem(Mood.BAD, "😟", "Bad"),
            MoodItem(Mood.TERRIBLE, "😢", "Terrible")
        )
        
        moods.forEach { moodItem ->
            val isSelected = plan.selectedMood == moodItem.mood
            
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
                    .clickable { viewModel.selectMood(moodItem.mood) },
                colors = CardDefaults.cardColors(
                    containerColor = if (isSelected)
                        MaterialTheme.colorScheme.primaryContainer
                    else
                        MaterialTheme.colorScheme.surface
                ),
                elevation = if (isSelected)
                    CardDefaults.cardElevation(defaultElevation = 8.dp)
                else
                    CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Row(
                    modifier = Modifier
                        .padding(20.dp)
                        .fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = moodItem.emoji,
                        fontSize = 48.sp,
                        modifier = Modifier.padding(end = 24.dp)
                    )
                    Text(
                        text = moodItem.label,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                    )
                }
            }
        }
    }
}

@Composable
fun NotesView(viewModel: PlannerViewModel) {
    val plan = viewModel.currentPlan
    var notes by remember { mutableStateOf(plan.notes ?: "") }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Text(
            text = "Daily Notes & Reflections",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        Card(
            modifier = Modifier
                .fillMaxSize()
        ) {
            TextField(
                value = notes,
                onValueChange = { 
                    notes = it
                    viewModel.updateNotes(it)
                },
                placeholder = { Text("Write your thoughts, reflections, or notes for the day...") },
                modifier = Modifier
                    .fillMaxSize()
                    .padding(8.dp),
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = Color.Transparent,
                    unfocusedContainerColor = Color.Transparent,
                    disabledContainerColor = Color.Transparent,
                ),
                minLines = 10
            )
        }
    }
}
