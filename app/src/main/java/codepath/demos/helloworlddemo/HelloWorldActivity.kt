package codepath.demos.helloworlddemo

import android.app.Activity
import android.os.Bundle
import android.view.Menu

class HelloWorldActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_hello_world)
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        // Inflate the menu; this adds items to the action bar if it is present.
        menuInflater.inflate(R.menu.activity_hello_world, menu)
        return true
    }
}