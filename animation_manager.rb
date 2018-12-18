class AnimationManager
  def initialize
    @animation_timer = 0
    @current_animation_max_time = 1
    @is_animating = false
  end

  def trigger_animation(time)
    @animation_timer = time
    @current_animation_max_time = time
  end

  #returns true if animation just finished
  def tick
    if @animation_timer > 0
      @animation_timer -= 1 
      return true if @animation_timer == 0
    end

    return false
  end

  def is_animating?
    return @animation_timer > 0
  end

  def progress
    return (@current_animation_max_time - @animation_timer) / (@current_animation_max_time*1.0)
  end
end