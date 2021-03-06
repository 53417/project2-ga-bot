# create_table "friends", force: :cascade do |t|
#     t.integer "user_id"
#     t.integer "friend_id"
#     t.datetime "created_at", precision: 6, null: false
#     t.datetime "updated_at", precision: 6, null: false
#   end


class FriendsController < ApplicationController
  before_action :authenticate_user

    def read_people
        people = User.all
        render json: people
    end

    def follow_user
        @friend = Friend.new(follow_params)
        @friend.save
    end

    def unfollow_user
        @friend = Friend.where(follow_params)
        @friend.each do |record|
            record.destroy
        end
    end
    
    def read_profile
        userid = params[:id]
        user = User.find_by :id => userid
        following_detail = []
        following = Friend.where(user_id: userid)
        following.each do |user|
            following_detail.push(User.find_by :id => user.friend_id)
        end
        followers_detail = []
        followers = Friend.where(friend_id: userid)
        followers.each do |user|
            followers_detail.push(User.find_by :id => user.user_id)
        end
        posts = Post.where(user_id: userid)
        @query = {
            "user": user, 
            "following": following_detail, 
            "followers": followers_detail,
            "posts": posts,
        }

        render json: @query
    end

    def feed
        userid = params[:id]
        user = User.find_by :id => userid
        following_detail = []
        following = Friend.where(user_id: userid)
        following.each do |user|
            following_detail.push(User.find_by :id => user.friend_id)
        end
        followers_detail = []
        followers = Friend.where(friend_id: userid)
        followers.each do |user|
            followers_detail.push(User.find_by :id => user.user_id)
        end
        posts = []
        following.each do |user|
            # user_posts = Post.where(user_id: user.friend_id)
            user_posts = ActiveRecord::Base.connection.exec_query("SELECT * FROM posts LEFT JOIN users ON users.id = posts.user_id WHERE user_id = #{user.friend_id}")
            user_posts.each do |post|
                # user_info = User.find_by :id => post.user_id
                # post[:first_name] = user_info.first_name
                # post[:last_name] = user_info.last_name
                # post[:username] = user_info.username
                posts.push(post)
            end
        end
        my_posts = Post.where(user_id: userid)
        @query = {
            "user": user, 
            "following": following_detail, 
            "followers": followers_detail,
            "posts": posts,
            "my_posts": my_posts,
    }
        render json: @query
    end

    def create_post
        @post = Post.new(post_params)

        if @post.save
        else
            render json: @post.errors, status: :unprocessable_entity
        end
    end

    private

    def follow_params
      params.require(:friend).permit(:user_id, :friend_id)
    end

    def post_params
        params.require(:post).permit(:user_id, :post_title, :post_content)
    end
end
