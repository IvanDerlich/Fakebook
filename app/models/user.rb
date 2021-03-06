# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: %i[facebook]
  validates :first_name, :last_name, :email, presence: true
  validates :first_name, length: { minimum: 2 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.freeze
  validates :email,
            length: { maximum: 255 },
            format: { with: VALID_EMAIL_REGEX },
            uniqueness: { case_sensitive: false }
  has_many :posts
  has_many :comments
  has_many :likes
  has_many :sent_friendships, class_name: 'Friendship', foreign_key: 'user_id'
  has_many :received_friendships, class_name: 'Friendship', foreign_key: 'friend_id'

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if (data = session['devise.facebook_data'] && session['devise.facebook_data']['extra']['raw_info'])
        user.email = data['email'] if user.email.blank?
      end
    end
  end

  def comments_post(post, text)
    comments.create!(
      post: post,
      text: text
    )
  end

  def likes_post(post)
    likes.create!(
      post: post
    )
  end

  def confirms_friendship(user)
    friendship = received_friendships.find do |item|
      item.user == user &&
        item.confirmed == false
    end
    friendship.confirmed = true
    friendship.save
    Friendship.create!(
      user: self,
      friend: user,
      confirmed: true,
      mirror: true
    )
  end

  def requests_friendship(receiver)
    friendship = sent_friendships.new(
      friend: receiver
    )
    if friendship.valid?
      friendship.save
    else
      errors.add(:not_to_itself, friendship.errors.messages[:not_to_itself])
      errors.add(:already_received, friendship.errors.messages[:already_received])
      errors.add(:already_sent, friendship.errors.messages[:already_sent])
      errors.add(:already_friends, friendship.errors.messages[:already_friends])
      false
    end
  end

  def friend?(user)
    friends.include?(user)
  end

  def friends
    friends_array = sent_friendships.map do |friendship|
      friendship.friend if friendship.confirmed && (friendship.mirror == false)
    end
    friends_array += received_friendships.map do |friendship|
      friendship.user if friendship.confirmed && (friendship.mirror == false)
    end
    friends_array.compact
  end

  def requests_sent
    sent_friendships.map { |friendship| friendship.friend unless friendship.confirmed }.compact
  end

  def requests_received
    received_friendships.map { |friendship| friendship.user unless friendship.confirmed }.compact
  end
end
