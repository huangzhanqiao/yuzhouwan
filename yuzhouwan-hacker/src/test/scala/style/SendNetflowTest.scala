package style

import com.yuzhouwan.spark.streaming.detect.SendNetflow

/**
 * Created by Benedict Jin on 2015/9/7.
 */
class SendNetflowTest extends UnitTestStyle {

  "Clean method" should "output a string" in {

    val s = "0,tcp,http,SF,229,9385,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,9,9,0.00,0.00,0.00,0.00,1.00,0.00,0.00,9,90,1.00,0.00,0.11,0.04,0.00,0.00,0.00,0.00,normal."
    SendNetflow.clean(s) should be("0,229,9385,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,9,9,0.00,0.00,0.00,0.00,1.00,0.00,0.00,9,90,1.00,0.00,0.11,0.04,0.00,0.00,0.00,0.00\tnormal.")
  }

  it should "throw Exception if an empty string is inputted" in {

    val emptyS = ""
    a[RuntimeException] should be thrownBy {
      SendNetflow.clean(emptyS)
    }
  }

}