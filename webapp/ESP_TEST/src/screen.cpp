#include <lvgl.h>
#include "screen.hpp"
lv_obj_t *mainScreen;
lv_obj_t *imgBackground;
lv_obj_t *pnBase;
lv_obj_t *currentLabel;
Button buttons[4];
int btn_positions[4][2] = {{-80, 0}, {0, -80}, {80, 0}, {0, 80}};
const char *btn_labels[4] = {LV_SYMBOL_LEFT, LV_SYMBOL_UP, LV_SYMBOL_RIGHT, LV_SYMBOL_DOWN};
byte btn_ids[4] = {0, 1, 2, 3};
extern void swap_turns();
extern void shift_player();
Button bswap2;
Button bswap;

void (*callback)(int) = nullptr;

void setOnButtonClickCallback(void (*cb)(int))
{
    callback = cb;
}

static void button_event_handler(lv_event_t *e)
{
    byte btn_id = *(byte *)lv_event_get_user_data(e);
    if (callback)
    {
        callback(btn_id);
    }
    // Serial.printf("Button %d clicked\n", btn_id);
}

void init_screen()
{
    lv_disp_t *dispp = lv_disp_get_default();
    lv_theme_t *theme = lv_theme_default_init(
        dispp, lv_palette_main(LV_PALETTE_BLUE),
        lv_palette_main(LV_PALETTE_RED),
        true, LV_FONT_DEFAULT);
    lv_disp_set_theme(dispp, theme);
    mainScreen = lv_obj_create(NULL);
    lv_obj_clear_flag(mainScreen, LV_OBJ_FLAG_SCROLLABLE);
    lv_disp_load_scr(mainScreen);
    lv_obj_set_style_bg_color(mainScreen, lv_color_hex(0x000000), LV_PART_MAIN | LV_STATE_DEFAULT);
    // Set Background Image
    imgBackground = lv_img_create(mainScreen);
    lv_img_set_src(imgBackground, &ui_img_1651235431);
    lv_obj_set_style_opa(imgBackground, 64, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_width(imgBackground, LV_SIZE_CONTENT);  /// 1
    lv_obj_set_height(imgBackground, LV_SIZE_CONTENT); /// 1
    lv_obj_align(imgBackground, LV_ALIGN_CENTER, 0, 0);
    pnBase = lv_obj_create(mainScreen);
    lv_obj_remove_style_all(pnBase);
    lv_obj_set_width(pnBase, lv_pct(100));
    lv_obj_set_height(pnBase, lv_pct(100));
    lv_obj_set_align(pnBase, LV_ALIGN_CENTER);
    lv_obj_clear_flag(pnBase, LV_OBJ_FLAG_SCROLLABLE); /// Flags

    for (int i = 0; i < 4; i++)
    {
        buttons[i].btn = lv_btn_create(pnBase);
        lv_obj_set_width(buttons[i].btn, 64);
        lv_obj_set_height(buttons[i].btn, 64);
        lv_obj_set_align(buttons[i].btn, LV_ALIGN_CENTER);
        lv_obj_align(buttons[i].btn, LV_ALIGN_CENTER, btn_positions[i][0], btn_positions[i][1]);
        buttons[i].label = lv_label_create(buttons[i].btn);
        lv_label_set_text(buttons[i].label, btn_labels[i]);
        lv_obj_set_style_text_font(buttons[i].label, &lv_font_montserrat_32, LV_PART_MAIN | LV_STATE_DEFAULT);
        lv_obj_center(buttons[i].label);
        lv_obj_add_event_cb(buttons[i].btn, button_event_handler, LV_EVENT_CLICKED, &btn_ids[i]);
    }

    currentLabel = lv_label_create(pnBase);
    lv_label_set_text(currentLabel, "A0");
    lv_obj_align(currentLabel, LV_ALIGN_CENTER, 0, 0);
    lv_obj_set_style_text_font(currentLabel, &lv_font_montserrat_48, LV_PART_MAIN | LV_STATE_DEFAULT);

    bswap.btn = lv_btn_create(pnBase);
    lv_obj_set_width(bswap.btn, 100);
    lv_obj_set_height(bswap.btn, 40);
    lv_obj_align(bswap.btn, LV_ALIGN_TOP_RIGHT, 0, 0);
    lv_obj_add_event_cb(bswap.btn, [](lv_event_t *e)
                        { swap_turns(); }, LV_EVENT_CLICKED, NULL);
    bswap.label = lv_label_create(bswap.btn);
    lv_label_set_text(bswap.label, "Player 1");
    lv_obj_set_style_text_font(bswap.label, &lv_font_montserrat_24, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_center(bswap.label);

    bswap2.btn = lv_btn_create(pnBase);
    lv_obj_set_width(bswap2.btn, 100);
    lv_obj_set_height(bswap2.btn, 40);
    lv_obj_align(bswap2.btn, LV_ALIGN_TOP_LEFT, 0, 0);
    lv_obj_add_event_cb(bswap2.btn, [](lv_event_t *e)
                        { shift_player(); }, LV_EVENT_CLICKED, NULL);
    bswap2.label = lv_label_create(bswap2.btn);
    lv_label_set_text(bswap2.label, "Shift");
    lv_obj_set_style_text_font(bswap2.label, &lv_font_montserrat_24, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_center(bswap2.label);
}

void setCurrentPlayer(bool player1)
{
    String s = player1 ? "Player 1" : "Player 2";
    lv_label_set_text(bswap.label, s.c_str());
}

void setCurrentLabel(uint8_t value)
{
    byte left = value >> 4;
    byte right = value & 0x0F;
    String s = "";
    switch (left)
    {
    case 0x00:
        s += "A";
        break;
    case 0x01:
        s += "B";
        break;
    case 0x02:
        s += "C";
        break;
    case 0x03:
        s += "D";
        break;
    case 0x04:
        s += "E";
        break;
    case 0x05:
        s += "F";
        break;
    case 0x06:
        s += "G";
        break;
    case 0x07:
        s += "H";
        break;
    default:
        break;
    }
    s += right;
    lv_label_set_text(currentLabel, s.c_str());
}