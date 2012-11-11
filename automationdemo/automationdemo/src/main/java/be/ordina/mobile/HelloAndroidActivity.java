package be.ordina.mobile;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import com.crittercism.app.Crittercism;

public class HelloAndroidActivity extends Activity {

    private static String TAG = "automationdemo";



    /**
     * Called when the activity is first created.
     * @param savedInstanceState If the activity is being re-initialized after
     * previously being shut down then this Bundle contains the data it most
     * recently supplied in onSaveInstanceState(Bundle). <b>Note: Otherwise it is null.</b>
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Crittercism.init(getApplicationContext(), "509fbfda3a474828a0000002");
        String hello = getString( R.string.hello);
        final String userName = getString( R.string.username);

        setContentView(R.layout.main);
        TextView helloLabel = (TextView) findViewById(R.id.helloLabel);
        helloLabel.setText( hello +  " " + userName);


        Button crashButton = (Button) findViewById(R.id.crashButton);
        crashButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View view) {
                throw new RuntimeException("crashing for user " + userName);
            }
        });


        Log.i(TAG, "onCreate");

    }

}

