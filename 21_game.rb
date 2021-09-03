# 21_game.rb

module Formattable
  def clear
    system('clear')
  end

  def blank_line
    puts
  end

  def joinor(arr, delimiter=', ', word='and')
    case arr.size
    when 0 then ''
    when 1 then arr.first
    when 2 then arr.join(" #{word} ")
    else
      arr[-1] = "#{word} #{arr.last}"
      arr.join(delimiter)
    end
  end
end

module Questionable
  include Formattable

  YES_NO_OPTIONS = %w(y yes n no)

  def ask_yes_no_question(question)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.downcase.strip
      break if YES_NO_OPTIONS.include? answer
      puts "Sorry, must be y or n."
      blank_line
    end
    answer[0] == 'y'
  end

  def ask_open_question(question, void_answer)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.strip
      break unless answer.empty? || answer == void_answer
      puts "Sorry, must enter a value (it can't be '#{void_answer}'!)."
      blank_line
    end
    answer
  end

  def ask_closed_question(question, options)
    downcase_options = options.map(&:downcase)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.downcase.strip
      break if downcase_options.include?(answer)
      puts "Sorry, invalid choice."
      blank_line
    end
    answer
  end
end

module Displayable
  include Formattable

  def display_welcome_message
    clear
    puts <<~WELCOME
    Hi #{player.name}. Welcome to Twenty-One!
    You are playing against #{dealer.name}.
    The first to win #{Game::WINS_LIMIT} games is the Champion!
    WELCOME
    blank_line
  end

  def display_initial_hand
    puts "#{name} has #{hand[0]} and an unknown card."
  end

  def display_hit
    puts "#{name} chose to hit."
  end

  def display_stay
    puts "#{name} chose to stay."
  end

  def display_hand
    puts "#{name} has #{joinor(hand.dup)}, for a total of #{total(hand)}."
  end

  def display_tie
    puts "It's a tie!"
  end

  def display_winner(participant)
    puts "#{participant.name} won!"
  end

  def display_scores
    puts "Score: #{player.name} = #{player.score}, #{dealer.name} = #{dealer.score}."
    blank_line
  end

  def display_busted(participant)
    puts "Oh dear, #{participant.name} has gone bust!"
  end

  def display_champion
    blank_line
    puts "#{champion.name} won #{Game::WINS_LIMIT} games and is the CHAMPION!"
    blank_line
  end

  def play_again?
    ask_yes_no_question("Would you like to play another match? (y/n)")
  end

  def continue_match_message
    blank_line
    answer = ask_closed_question(
      "Press enter to continue the match (or 'q' to quit this match).",
      ["", "q"]
    )
    clear
    answer.empty? ? true : false
  end

  def display_rematch_message
    clear
    puts <<~REMATCH
    Hi #{player.name}. Welcome back to Twenty-One!
    You are playing against #{dealer.name}.
    Remember, the first to win #{Game::WINS_LIMIT} games is the Champion!
    REMATCH
    blank_line
  end

  def display_goodbye_message
    puts "Thank you for playing Twenty-One! Goodbye!"
    blank_line
  end
end

module Hand
  def total(hand)
    value = 0
    aces = hand.each_with_object([]) do |card, arr|
      arr << 'Ace' if card.rank == 'Ace'
      value += Deck::CARD_RANKS_AND_VALUES.fetch(card.rank)
    end
    aces.each { value += Deck::ACE_VALUE_ALTERNATE if value <= Deck::ACE_VALUE_LIMIT }
    value
  end

  def busted?(hand)
    total(hand) > Game::BUST_VALUE
  end
end

class Participant
  include Displayable
  include Questionable
  include Hand

  DEALER_NAME = "Alice"

  attr_reader :name, :deck
  attr_accessor :hand, :score

  def initialize(deck)
    @hand = []
    @score = 0
    @deck = deck
  end

  def show_hand
    display_hand
  end

  def hit
    hand << deck.deal_card
    display_hit
  end

  def stay
    display_stay
  end

  def increment_score
    self.score += 1
  end

  def reset_hand
    self.hand = []
  end

  def reset_score
    self.score = 0
  end
end

class Player < Participant
  def initialize(deck)
    @name = ask_open_question("What's your name?", DEALER_NAME)
    super
  end
end

class Dealer < Participant
  def initialize(deck)
    @name = DEALER_NAME
    super
  end

  def show_initial_hand
    display_initial_hand
  end
end

class Deck
  HEART = "\u2665"
  CLUB = "\u2663"
  DIAMOND = "\u2666"
  SPADE = "\u2660"

  CARD_SUITS = [HEART, CLUB, DIAMOND, SPADE]
  CARD_RANKS_AND_VALUES = {
    '2' => 2, '3' => 3, '4' => 4, '5' => 5, '6' => 6, '7' => 7, '8' => 8,
    '9' => 9, '10' => 10, 'Jack' => 10, 'Queen' => 10, 'King' => 10, 'Ace' => 1
  }

  ACE_VALUE_ALTERNATE = 10
  ACE_VALUE_LIMIT = 11

  attr_accessor :cards

  def initialize
    reset
  end

  def initial_deal(player, dealer)
    2.times do
      player.hand << deal_card
      dealer.hand << deal_card
    end
  end

  def deal_card
    cards.pop
  end

  def reset
    self.cards = CARD_SUITS.each_with_object([]) do |suit, arr|
    CARD_RANKS_AND_VALUES.keys.each do |rank|
      arr << Card.new(rank, suit)
    end
  end
  cards.shuffle!
  end
end

class Card
  attr_reader :rank, :suit

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
  end

  def to_s
    "#{rank}#{suit}"
  end
end

class Game
  include Displayable
  include Questionable
  include Hand

  WINS_LIMIT = 5
  BUST_VALUE = 21
  DEALER_STAY_VALUE = 17

  attr_reader :player, :dealer
  attr_accessor :deck, :winner, :champion

  def initialize
    clear
    @deck = Deck.new
    @player = Player.new(deck)
    @dealer = Dealer.new(deck)
    @winner = nil
    @champion = nil
  end

  def start
    display_welcome_message
    loop do
      main_game
      display_champion if champion
      break unless play_again?
      reset_match
      display_rematch_message
    end
    display_goodbye_message
  end

  private

  def main_game
    loop do
      display_scores
      deal_cards
      display_initial_cards
      player_turn
      dealer_turn if !busted?(player.hand)
      determine_result
      update_score if winner
      break if match_champion
      reset_game
      break unless continue_match_message
    end
  end

  def deal_cards
    deck.initial_deal(player, dealer)
  end

  def display_initial_cards
    dealer.show_initial_hand
    player.show_hand
  end

  def player_turn
    loop do
      choice = ask_closed_question(
        "Would you like to (h)it or (s)tay?", ['h', 's']
      )
      if choice == 's'
        player.stay
        return
      end
      player.hit
      player.show_hand
      break if busted?(player.hand)
    end
    display_busted(player)
  end

  def dealer_turn
    dealer.show_hand
    while total(dealer.hand) < DEALER_STAY_VALUE
      dealer.hit
      dealer.show_hand
    end
    if busted?(dealer.hand)
      display_busted(dealer)
    else
      dealer.stay
    end
  end

  def determine_result
    self.winner = determine_winner
    declare_winner
  end

  def determine_winner
    if busted?(player.hand) then dealer
    elsif busted?(dealer.hand) then player
    elsif total(player.hand) > total(dealer.hand) then player
    elsif total(dealer.hand) > total(player.hand) then dealer
    end
  end

  def declare_winner
    case winner
    when nil then display_tie
    else display_winner(winner)
    end
  end

  def update_score
    winner.increment_score
  end

  def match_champion
    self.champion = if player.score == WINS_LIMIT
                      player
                    elsif dealer.score == WINS_LIMIT
                      dealer
                    end
  end

  def reset_game
    deck.reset
    player.reset_hand
    dealer.reset_hand
    self.winner = nil
  end

  def reset_match
    reset_game
    player.reset_score
    dealer.reset_score
    self.champion = nil
  end
end

Game.new.start