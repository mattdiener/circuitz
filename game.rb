require 'gosu'
require 'io/console'

require_relative 'game_info'
require_relative 'game_board'
require_relative 'animation_manager'

STDOUT.sync = true

class CircuitzGame < Gosu::Window
  def initialize
    @screen_width = 640
    @screen_height = 480

    super(@screen_width, @screen_height)

    self.caption = "Circuitz"

    initialize_debug_console
    initialize_game_info
    initialize_animation_manager
    initialize_game_board

    start_game
  end

  def initialize_debug_console
    @debug_console_thread = Thread.new do handle_console end
  end

  def initialize_game_info
    @game_info = GameInfo.new()
    @game_info.initialize_font(Gosu::Font.new(self, Gosu::default_font_name, 24))
    @game_info.initialize_screen_size(@screen_width, @screen_height)
  end

  def initialize_game_board
    @game_board = GameBoard.new(@game_info, @animation_manager)
  end

  def initialize_animation_manager
    @animation_manager = AnimationManager.new()
  end

  def start_game
    @game_board.load_level("world1/level1")
  end

  def post_init
    end_animation()
  end

  def close
    super
    @debug_console_thread.kill
  end

  def handle_console
    STDIN.each_line do |line|
      command, *args = line.split(" ")

      case command
      when "save"
        @game_board.save_as(args[0], false) if args[0]
      when "save_hard"
        @game_board.save_as(args[0], true) if args[0]
      when "load"
        @game_board.load_level(args[0]) if args[0]
      end
    rescue => e
      puts e
    end
  end

  def button_down(btn)
    #handle toggles
    case btn
    when Gosu::KB_BACKTICK
      @game_info.toggle_debug_mode
    when Gosu::KB_F1
      @game_info.toggle_show_rotations
    when Gosu::KB_F2
      @game_info.toggle_level_completion
    end

    #general controls debug/game
    if @game_info.debug_mode
      debug_button_down(btn)
    else
      game_button_down(btn)
    end
  end

  def game_button_down(btn)
  end

  def handle_held_game_buttons
    #we call this over game_button_down if we want this to re-fire every frame the button is being held
    if self.button_down?(Gosu::MsLeft)
      @game_board.handle_left_click
    elsif self.button_down?(Gosu::MsRight)
      @game_board.handle_right_click
    end
  end

  def debug_button_down(btn)
    case btn
    when Gosu::KB_W
      @game_board.handle_debug_swap_key(:up)
    when Gosu::KB_A
      @game_board.handle_debug_swap_key(:left)
    when Gosu::KB_S
      @game_board.handle_debug_swap_key(:down)
    when Gosu::KB_D
      @game_board.handle_debug_swap_key(:right)
    when Gosu::KB_Q
      @game_board.handle_debug_rotate_key(-1)
    when Gosu::KB_E
      @game_board.handle_debug_rotate_key(1)
    when Gosu::KB_R
      @game_board.handle_debug_next_backboard
    when Gosu::KB_T
      @game_board.handle_debug_next_tile
    when Gosu::KB_I
      @game_board.debug_resize(:up)
    when Gosu::KB_J
      @game_board.debug_resize(:left)
    when Gosu::KB_K
      @game_board.debug_resize(:down)
    when Gosu::KB_L 
      @game_board.debug_resize(:right)
    end
  end

  def needs_cursor?
    return true
  end

  def update
    end_animation if @animation_manager.tick
    handle_held_game_buttons if not @game_info.debug_mode
    @game_board.update_mouse_boxes(self.mouse_x, self.mouse_y)
  end
  
  def draw
    draw_bg
    @game_board.draw
    draw_overlay
  end

  def end_animation()
    @game_board.end_animation

    if @game_info.state == :fade_in
      @game_info.state = :game
    elsif @game_info.state == :fade_out
      @game_board.load_next_level
    elsif @game_board.level_done? and @game_info.enable_level_completion
      @game_info.state = :fade_out
      @animation_manager.trigger_animation(FADE_TIME)
    end
  end

  def draw_bg
    Gosu.draw_rect(0,0,self.width,self.height,COLOR_GREY, Z_BG)
  end

  def draw_overlay
    animation_progress = @animation_manager.progress

    if @game_info.debug_mode
      #DEBUG_WARNING
      @game_info.default_font.draw_text("DEBUG",
                                        0, 0, Z_OVERLAY,
                                        1, 1, Gosu::Color::GREEN)

      #BOX_SIZE
      @game_info.default_font.draw_text_rel("#{@game_board.width}x#{@game_board.height}",
                                            0, self.height, Z_OVERLAY,
                                            0, 1.0, 1, 1, Gosu::Color::GREEN)
    end

    if not @game_info.enable_level_completion 
      color = Gosu::Color::RED
      if @game_board.level_done?
        color = Gosu::Color::GREEN
      end

      @game_info.default_font.draw_text_rel("level transitions disabled",
                                            self.width, 0, Z_OVERLAY,
                                            1.0, 0, 1, 1, color)
    end

    if @game_info.state == :fade_in
      color = Gosu::Color.new(255*(1-animation_progress),0,0,0)
      Gosu.draw_rect(0, 0, self.width, self.height, color, Z_OVERLAY)
    elsif @game_info.state == :fade_out
      color = Gosu::Color.new(255*(animation_progress),0,0,0)
      Gosu.draw_rect(0, 0, self.width, self.height, color, Z_OVERLAY)
    end
  end
end

$game = CircuitzGame.new()
$game.post_init()
$game.show()