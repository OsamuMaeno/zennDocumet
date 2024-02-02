---
title: "M5CoreInkの家庭内での実用について"
emoji: "🛰"
type: "tech"
topics: [m5stack,m5coreink,platformio,cpp]
published: true
published_at: 2024-02-13 08:00
publication_name: "secondselection"
---

## はじめに

セカンドセレクションの前野です。M5Stack大好きで、これらで何ができるだろうと日々考えているうちに、M5Stackが部屋に溜まっていっています。
そんな私もM5CoreInkを見た時に使い道が考えられませんでした。

そうM5CoreInkはこれです。(Switch Scienceさんのサイトへ飛びます)

https://ssci.to/6735

M5Stackの液晶が電子ペーパーになった感じです。

そんなM5CoreInkが我が家で働く場所を見つけました。

## 経緯

節水型洗濯機に買い替えたことが発端です。

前の洗濯機は風呂のお湯を使って洗っていました。２日に1回お湯を使っていたので、ああ今日は風呂を洗う日なんだと認識出来ていました。

しかし節水型洗濯機を使うようになってお風呂の湯を使わなくなりました。そのせいでお風呂を洗うタイミングを記憶する必要が出てきました。
40歳を超えると些細なことを覚えるのが億劫となってきて、機械に覚えてもらおうということとなりました。

### スマホでアラーム
スマホでアラームするほどではないし、ほぼ毎日アラームが入っているのも嫌でした。

### そこでM5CoreInk
M5CoreInkはよく出来ています。電子ペーパーなんでリアルタイムで画面を書き換えるのは苦手ですが、CPUが動いていなくても画面の表示は消えません。
画面の大きさもそこそこで、大き目な字で表示すれば遠くからでも見えます。

1日1回画面の表示を書き換えるだけなので一度充電すれば数ヶ月持ちます。

## 動作

1日ごとに表示がWashとNothingに切り替わります。

- 洗わない日

![洗わない日](/images/used_m5coreink/m5coreink_nothing.jpg)

- 洗う日

![洗う日](/images/used_m5coreink/m5coreink_wash.jpg)


RTCで夜中の0時に起動してtime_tの日数が奇数だったらWash、偶数だったらNothingと表示します。
表示を切り替えたらCPUは終了します。

## ソース

PlatformIOにて開発していますが、Arduinoで動かすのはそんな難しくないでしょう。


```cpp
#include "M5CoreInk.h"
#include "esp_adc_cal.h"
#include <Preferences.h>
#include <time.h>

int wash_flag;

#define ALARM_HOUR  0
#define ALARM_MIN   1

Preferences prefs;

int cnt;
RTC_TimeTypeDef RTCtime;
RTC_DateTypeDef RTCDate;

Ink_Sprite InkPageSprite(&M5.M5Ink); 

float getBatVoltage()
{
    analogSetPinAttenuation(35,ADC_11db);
    esp_adc_cal_characteristics_t *adc_chars = (esp_adc_cal_characteristics_t *)calloc(1, sizeof(esp_adc_cal_characteristics_t));
    esp_adc_cal_characterize(ADC_UNIT_1, ADC_ATTEN_DB_11, ADC_WIDTH_BIT_12, 3600, adc_chars);
    uint16_t ADCValue = analogRead(35);
    
    uint32_t BatVolmV  = esp_adc_cal_raw_to_voltage(ADCValue,adc_chars);
    float BatVol = float(BatVolmV) * 25.1 / 5.1 / 1000;
    return BatVol;
}

char timeStrbuff[64];
tm timeNow;
tm timeMem;
time_t now;

void flushTime(){
   M5.rtc.GetTime(&RTCtime);
   M5.rtc.GetDate(&RTCDate);
   
   sprintf(timeStrbuff,"%d/%02d/%02d %02d:%02d:%02d",
                       RTCDate.Year,RTCDate.Month,RTCDate.Date,
                       RTCtime.Hours,RTCtime.Minutes,RTCtime.Seconds);
                                        
   InkPageSprite.drawString(10,10,timeStrbuff);
 }

void setup(){
  M5.begin();

  digitalWrite(LED_EXT_PIN,LOW);
  M5.M5Ink.clear(INK_CLEAR_MODE1);

  //creat ink Sprite.
  if( InkPageSprite.creatSprite(0,0,200,200,true) != 0 ){
      Serial.printf("Ink Sprite creat faild");
  }
  prefs.begin("bath");
  prefs.getBytes("time", &timeMem, sizeof(timeMem));
  prefs.end();

  flushTime();
  timeNow.tm_year = RTCDate.Year-1900;
  timeNow.tm_mon = RTCDate.Month-1;
  timeNow.tm_mday = RTCDate.Date;
  now = mktime(&timeNow);
  wash_flag = ((int)now/86400) % 2;
  Serial.printf("%ld %d/%02d/%02d\n", now, timeNow.tm_year,timeNow.tm_mon,timeNow.tm_mday);
  Serial.printf("%d/%02d/%02d\n", timeMem.tm_year,timeMem.tm_mon,timeMem.tm_mday);
  prefs.begin("bath");
  prefs.putBytes("time", &timeMem, sizeof(timeMem));
  prefs.end();
  InkPageSprite.drawString(10,50,String(wash_flag).c_str());
  InkPageSprite.drawString(50,50,String(getBatVoltage()).c_str());
  if (wash_flag == 0 )
  {
    InkPageSprite.drawString(10,80,"Wash", &AsciiFont24x48);
  }
  else {
    InkPageSprite.drawString(10,80,"Nothing", &AsciiFont24x48);
  }
  InkPageSprite.pushSprite();
  
  Serial.println("shutdown start");
  if ( RTCtime.Hours == ALARM_HOUR && RTCtime.Minutes == ALARM_MIN ) {
    delay(60*1000);
  }
  InkPageSprite.drawString(10,150,"shutdown start");
  InkPageSprite.pushSprite();
  
  M5.shutdown(RTC_TimeTypeDef(ALARM_HOUR,ALARM_MIN,0));

}

void loop(){
}
```

## あとがき

M5CoreInkを何かに使えないかなからの需要が発生して実用化というのはとても嬉しいです。
後、プログラムの実行は自己責任でお願いします。

