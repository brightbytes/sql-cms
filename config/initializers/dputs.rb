# These are for quick debugging
class ::Object

  require 'pp'

  def dputs(*msgs)
    puts_asterisks
    puts(*msgs.map(&:to_s))
    puts_asterisks
  end

  def dpp(*os)
    puts_asterisks
    pp(*os)
    puts_asterisks
  end

  def ddebug(*args)
    puts_asterisks
    Rails.logger.debug(*args)
    puts_asterisks
  end

  def dppstack(*msgs)
    puts_asterisks
    dputs(*(msgs << caller.join("\n")))
    puts_asterisks
  end

  private

  ASTERISKS = "*" * 80 unless defined?(ASTERISKS)

  def puts_asterisks
    puts ASTERISKS
  end
end
