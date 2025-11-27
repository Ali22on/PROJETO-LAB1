#include <lvgl.h>
#include <TFT_eSPI.h>
#include <../lib/ui/ui.h>
#include <WiFi.h>
#include <Wire.h>
#include <ArduinoOTA.h>
#include <../lib/boardstuff/boardstuff.h>
// #define MQTT_SOCKET_TIMEOUT 2
#include <../lib/pubsubclient-2.8/src/PubSubClient.h>
#include <../include/Creds/WifiCred.h>
#include <../include/Creds/HiveMQCred.h>
#include <../lib/Time-master/TimeLib.h>
#include <NightMareNetwork.h>
#include <lvgl_helper.h>
/******************************************/

static byte player1_pos;
static byte player1_score;
static byte player2_pos;
static byte player2_score;
static bool player1_turn = true;
static byte player1_map[64];
static byte player2_map[64];
void sendSerial();
void move_player(bool player1, int x_delta, int y_delta)
{
    byte base = player1 ? player1_pos : player2_pos;
    byte left = base >> 4;
    byte right = base & 0x0F;
    int new_left = (int)(left) + x_delta;
    int new_right = (int)(right) + y_delta;
    if (new_left < 0)
        new_left = 7;
    if (new_left > 7)
        new_left = 0;
    if (new_right < 0)
        new_right = 7;
    if (new_right > 7)
        new_right = 0;
    byte new_pos = (new_left << 4) | (new_right & 0x0F);
    // Serial.printf("Player %d moved to %02X, [x: %d, y: %d] [l:%d, r:%d] [nl: %d, nr: %d]\n", player1 ? 1 : 2, new_pos, x_delta, y_delta, left, right, new_left >> 4, new_right);
    if (player1)
        player1_pos = new_pos;
    else
        player2_pos = new_pos;
}

void onButtonClick(int btn_id)
{
    int x = 0;
    int y = 0;

    switch (btn_id)
    {
    case 0:
        move_player(player1_turn, -1, 0);
        break;
    case 1:
        move_player(player1_turn, 0, -1);
        break;
    case 2:
        move_player(player1_turn, 1, 0);
        break;
    case 3:
        move_player(player1_turn, 0, 1);
        break;
    }
    setCurrentLabel(player1_turn ? player1_pos : player2_pos);
    sendSerial();   
}

void swap_turns()
{
    return;
    player1_turn = !player1_turn;
    setCurrentPlayer(player1_turn);
    setCurrentLabel(player1_turn ? player1_pos : player2_pos);
}
static int count = 0;
extern lv_obj_t * currentLabel;
void shift_player()
{
    count = 0;
    lv_label_set_text(currentLabel, String(count).c_str());
    return;
    byte first = player1_turn ? player1_map[0] : player2_map[0];
    for (int i = 0; i < 63; i++)
    {
        if (player1_turn)
        {
            player1_map[i] = (player1_map[i + 1] );
        }
        else
        {
            player2_map[i] = (player2_map[i + 1]);
        }
    }
    if (player1_turn)
    {
        player1_map[63] = first;
    }
    else
    {
        player2_map[63] = first;
    }
     sendSerial();
}

void sendSerial()
{
    for (size_t i = 0; i < 64; i++)
    {
        Serial.write(player1_map[i]);
    }
    for (size_t i = 0; i < 64; i++)
    {
        Serial.write(player2_map[i]);
    }
    Serial.write(player1_score);
    Serial.write(player2_score);
    Serial.write(player1_pos);
    Serial.write(player2_pos);
}

void setup()
{
    set_backlight(0);
    Serial.begin(115200); /* prepare for possible serial debug */
    board_init();
    lvgl_init();

}

void loop()
{
    lv_timer_handler();
    if (Serial.available())
    {
        while (Serial.available())
        {
            count ++;
            byte incoming = Serial.read();
            Serial.write(incoming); // Echo back for debug
            lv_label_set_text(currentLabel, String(count).c_str());
        }
        
    }
}
