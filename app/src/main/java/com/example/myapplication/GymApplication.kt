package com.example.myapplication

import android.app.Application
import com.example.myapplication.app.AppContainer

class GymApplication : Application() {
    val container: AppContainer by lazy { AppContainer(applicationContext) }
}
