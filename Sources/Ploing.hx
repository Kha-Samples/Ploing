//
// A Pong game demo
//

package;

import kha.Assets;
import kha.Color;
import kha.FontStyle;
import kha.Framebuffer;
import kha.input.Gamepad;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.Key;
import kha.Scaler;
import kha.Image;
import kha.Scheduler;
import kha.System;

class Ploing {
	// Pad sizes and speeds
	static public var PAD_WIDTH  = 20;
	static public var PAD_HEIGHT = 80;
	static public var PAD1_SPEED = 5.0;
	static public var PAD2_SPEED = 2.0; // Pad 2 is controlled by the computer
	
	// Ball sizes and speeds
	static public var BALL_WIDTH      = 20;
	static public var BALL_HEIGHT     = 20;
	static public var BALL_SPEED_STEP = 1.0;
	static public var MAX_BALL_SPEED  = 12.0;
	
	// Player and pad variables
	var pad1_x: Float;
	var pad1_y: Float;
	var pad2_x: Float;
	var pad2_y: Float;
	var score: Int;
	
	// Ball variables
	var ball_x: Float;
	var ball_y: Float;
	var ball_speedx: Float;
	var ball_speedy: Float;
	var ball_speed: Float; // Ball speed, always positive, independent of direction
	
	// Player controls, set by the button handlers
	var up  : Bool;
	var down: Bool;
	
	var backbuffer: Image;
	
	// Constructor
	public function new() {
		resetPositionsAndSpeeds();
		
		up   = false;
		down = false;
		
		score = 0;
		
		backbuffer = Image.createRenderTarget(640, 480);
		Assets.loadEverything(function () {
			System.notifyOnRender(render);
			Scheduler.addTimeTask(update, 0, 1 / 60);
			if (Keyboard.get() != null) Keyboard.get().notify(keyDown, keyUp);
			if (Gamepad.get() != null) Gamepad.get().notify(axis, null);
			if (Mouse.get() != null) Mouse.get().notify(null, null, mouseMove, null);
		});
	}
	
	// Reset positions and speeds of both pads and the ball
	private function resetPositionsAndSpeeds(): Void {
		pad1_x = 0;
		pad1_y = 240 - PAD_HEIGHT / 2;
		
		pad2_x = 640 - PAD_WIDTH;
		pad2_y = 240 - PAD_HEIGHT / 2;
		
		ball_speed  = 3;
		ball_x      = 320 - BALL_WIDTH / 2;
		ball_y      = 240 - BALL_HEIGHT / 2;
		ball_speedx = -ball_speed; // Negative, so that it will fly to the player's pad at the left side first
		ball_speedy = 0;
	}
	
	// Increase ball speed, but not over a maximum speed
	private function increaseBallSpeed(): Void {
		ball_speed += BALL_SPEED_STEP;
		if (ball_speed > MAX_BALL_SPEED) ball_speed = MAX_BALL_SPEED;
	}
	
	// Calculate an y speed for when a ball collides with a pad,
	// based on where both are in comparison to each other.
	private function getBallYSpeed(pad_mid_y: Float, ball_mid_y: Float): Float {
		// If the ball's center is at a lower position compared to
		// the pad's center, the y speed will be higher, which will
		// make the ball move faster in the down-direction.
		var v: Float = (ball_mid_y - pad_mid_y) / PAD_HEIGHT;
		return v * 4.0;
	}

	private function update(): Void {
		// Move ball
		ball_x += ball_speedx;
		ball_y += ball_speedy;
		
		// Let ball bounce back from the top and bottom screen borders
		if (ball_y < 0.0) {
			ball_y = 0.0;
			ball_speedy = -ball_speedy;
		}
		if (ball_y + BALL_HEIGHT > 480.0) {
			ball_y = 480.0 - BALL_HEIGHT;
			ball_speedy = -ball_speedy;
		}
		
		// If the ball passes the left or right screen borders, the player's score decreases or increases and the game is restarted
		if (ball_x >= 640.0) {
			resetPositionsAndSpeeds();
			score++;
			return;
		}
		if (ball_x + BALL_WIDTH <= 0.0) {
			resetPositionsAndSpeeds();
			score--;
			return;
		}
		
		// Move the player's pad, according to wheather the up or down button is pressed
		if (up == true) {
			pad1_y -= PAD1_SPEED;
			if (pad1_y < 0.0) pad1_y = 0.0; // Do not move beyond screen border
		}
		if (down == true) {
			pad1_y += PAD1_SPEED;
			if (pad1_y + PAD_HEIGHT > 480.0) pad1_y = 480.0 - PAD_HEIGHT; // Do not move beyond screen border
		}
		
		// Very simple AI for the computer's pad
		//
		// It just tries to move so that the ball's center is in the pad's center.
		if (pad2_y + PAD_HEIGHT / 2.0 < ball_y + BALL_HEIGHT / 2.0) {
			// Pad center is above ball center, so move the pad down.
			// Do not move it so far that the pad center would become
			// below the ball center.
			pad2_y += PAD2_SPEED;
			if (pad2_y + PAD_HEIGHT / 2.0 > ball_y + BALL_HEIGHT / 2.0) pad2_y = ball_y + BALL_HEIGHT / 2.0 - PAD_HEIGHT / 2.0;
		}
		if (pad2_y + PAD_HEIGHT / 2.0 > ball_y + BALL_HEIGHT / 2.0) {
			// Like above, but in the opposite direction.
			pad2_y -= PAD2_SPEED;
			if (pad2_y + PAD_HEIGHT / 2.0 < ball_y + BALL_HEIGHT / 2.0) pad2_y = ball_y + BALL_HEIGHT / 2.0 - PAD_HEIGHT / 2.0;
		}
		// Do not move beyond screen borders:
		if (pad2_y < 0.0) pad2_y = 0.0;
		if (pad2_y + PAD_HEIGHT > 480.0) pad2_y = 480.0 - PAD_HEIGHT;
		
		// Create collision rectangles
		var pad1_rect: Rectangle = new Rectangle(pad1_x, pad1_y, PAD_WIDTH , PAD_HEIGHT );
		var pad2_rect: Rectangle = new Rectangle(pad2_x, pad2_y, PAD_WIDTH , PAD_HEIGHT );
		var ball_rect: Rectangle = new Rectangle(ball_x, ball_y, BALL_WIDTH, BALL_HEIGHT);
		// Collision between the player's pad and ball
		if (pad1_rect.collision(ball_rect)) {
			// The ball is bounced back and the ball speed is increased to make the game harder over time.
			// The ball y speed will be changed according to where on the pad the ball has collided.
			ball_speedx = ball_speed;
			ball_speedy += getBallYSpeed(pad1_y + PAD_HEIGHT / 2.0, ball_y + BALL_HEIGHT / 2.0);
			increaseBallSpeed();
		}
		// Collision between the computer's pad and ball
		if (pad2_rect.collision(ball_rect)) {
			// Bounce back the ball
			ball_speedx = -ball_speed;
			ball_speedy += getBallYSpeed(pad2_y + PAD_HEIGHT / 2.0, ball_y + BALL_HEIGHT / 2.0);
		}
	}
	
	private function render(frame: Framebuffer): Void {
		var g = backbuffer.g2;
		
		g.begin();
		
		g.clear();
		
		g.color = Color.White;
		
		// Draw pads and ball
		g.fillRect(pad1_x, pad1_y, PAD_WIDTH, PAD_HEIGHT);
		g.fillRect(pad2_x, pad2_y, PAD_WIDTH, PAD_HEIGHT);
		g.fillRect(ball_x, ball_y, BALL_WIDTH, BALL_HEIGHT);
		
		// Draw score at the top left of the screen
		g.font = Assets.fonts.LiberationSans_Regular;
		g.fontSize = 14;
		g.drawString(Std.string(score), 0, 0);
		g.end();
		
		frame.g2.begin();
		Scaler.scale(backbuffer, frame, System.screenRotation);
		frame.g2.end();
	}
	
	// Input handlers. Update up and down variables
	
	private function keyDown(key: Key, char: String): Void {
		switch (key) {
			case UP:
				up = true;
			case DOWN:
				down = true;
			default:
		}
	}
	
	private function keyUp(key: Key, char: String): Void {
		switch (key) {
			case UP:
				up = false;
			case DOWN:
				down = false;
			default:
		}
	}
	
	private function axis(axis: Int, value: Float): Void {
		if (axis == 1) {
			if (value > 0.1) {
				up = true;
				down = false;
			}
			else if (value < -0.1) {
				down = true;
				up = false;
			}
			else {
				up = false;
				down = false;
			}
		}
	}
	
	private function mouseMove(x: Int, y: Int, movementX: Int, movementY: Int): Void {
		pad1_y = y / System.pixelHeight * backbuffer.height - PAD_HEIGHT / 2;
	}
}
