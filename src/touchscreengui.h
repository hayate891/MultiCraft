/*
Copyright (C) 2014 sapier

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 3.0 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#ifndef TOUCHSCREENGUI_HEADER
#define TOUCHSCREENGUI_HEADER

#include <IEventReceiver.h>
#include <IGUIButton.h>
#include <IGUIEnvironment.h>

#include <map>
#include <vector>

#include "client/tile.h"
#include "game.h"

//#define ENABLE_ANDROID_NOCLIP

using namespace irr;
using namespace irr::core;
using namespace irr::gui;

typedef enum {
	forward_one = 0,
	forward_two,
	forward_three,
	backward_one,
	backward_two,
	backward_three,
	left_id,
	right_id,
	inventory_id,
	drop_id,
	jump_id,
	crunch_id,
#ifdef ENABLE_ANDROID_NOCLIP
	fly_id,
	noclip_id,
	fast_id,
#endif
	minimap_id,
//	debug_id,
	chat_id,
//	camera_id,
	range_id,
	range_ios_id,
	empty_id,
	escape_id,
	after_last_element_id
} touch_gui_button_id;

#define MIN_DIG_TIME_MS 500
#define BUTTON_REPEAT_DELAY 0.2f

class TouchScreenGUI
{
public:
	TouchScreenGUI(IrrlichtDevice *device, IEventReceiver *receiver);
	~TouchScreenGUI();

	void translateEvent(const SEvent &event);

	void init(ISimpleTextureSource *tsrc);

	double getYawChange()
	{
		double res = m_camera_yaw_change;
		m_camera_yaw_change = 0;
		return res;
	}

	double getPitch() { return m_camera_pitch; }

	line3d<f32> getShootline() { return m_shootline; }

	void step(float dtime);
	void resetHud();
	void registerHudItem(int index, const rect<s32> &rect);
	void Toggle(bool visible);

	void hide();
	void show();

#ifdef __IOS__
	void handleReleaseAll();
#endif

private:
	IrrlichtDevice*         m_device;
	IGUIEnvironment*        m_guienv;
	IEventReceiver*         m_receiver;
	ISimpleTextureSource*   m_texturesource;
	v2u32                   m_screensize;
	std::map<int,rect<s32> > m_hud_rects;
	std::map<size_t,irr::EKEY_CODE> m_hud_ids;
	bool                    m_visible; // is the gui visible

	/* value in degree */
	double m_camera_yaw_change;
	double m_camera_pitch;

	line3d<f32> m_shootline;

	rect<s32> m_control_pad_rect;

	int m_move_id;
	bool m_move_has_really_moved;
	s64 m_move_downtime;
	bool m_move_sent_as_mouse_event;
	v2s32 m_move_downlocation;

	struct button_info {
		float            repeatcounter;
		float            repeatdelay;
		irr::EKEY_CODE   keycode;
		std::vector<size_t> ids;
		IGUIButton*      guibutton;
		bool             immediate_release;
	};

	button_info m_buttons[after_last_element_id];

	/* gui button detection */
	touch_gui_button_id getButtonID(s32 x, s32 y);

	/* gui button by eventID */
	touch_gui_button_id getButtonID(size_t eventID);

	/* check if a button has changed */
	void handleChangedButton(const SEvent &event);

	/* initialize a button */
	void initButton(touch_gui_button_id id, rect<s32> button_rect,
			std::wstring caption, bool immediate_release,
			float repeat_delay = BUTTON_REPEAT_DELAY);

	/* load texture */
	void loadButtonTexture(button_info *btn, const char *path, rect<s32> button_rect);

	struct id_status
	{
		int id;
		int X;
		int Y;
	};

	/* vector to store known ids and their initial touch positions*/
	std::vector<id_status> m_known_ids;

	/* handle a button event */
	void handleButtonEvent(touch_gui_button_id bID, size_t eventID, bool action);

	/* handle pressed hud buttons */
	bool isHUDButton(const SEvent &event);

	/* handle released hud buttons */
	bool isReleaseHUDButton(size_t eventID);

	/* handle double taps */
	bool doubleTapDetection();

	/* handle release event */
	void handleReleaseEvent(size_t evt_id);

	/* get size of regular gui control button */
	int getGuiButtonSize();

	/* doubleclick detection variables */
	struct key_event
	{
		unsigned int down_time;
		s32 x;
		s32 y;
	};

	/* array for saving last known position of a pointer */
	std::map<size_t, v2s32> m_pointerpos;

	/* array for doubletap detection */
	key_event m_key_events[2];

	void storePointerPos(size_t ID, v2s32 pos);
	v2s32 loadPointerPos(size_t ID);
};
extern TouchScreenGUI *g_touchscreengui;
#endif
