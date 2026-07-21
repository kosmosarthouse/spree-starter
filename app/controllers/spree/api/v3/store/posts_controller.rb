module Spree
  module Api
    module V3
      module Store
        # Public, read-only endpoint exposing published blog posts to the
        # headless Next.js storefront. The spree_posts gem only ships admin
        # management routes (/admin/posts) with no public API — this fills
        # that gap.
        class PostsController < Spree::Api::V3::Store::BaseController
          # Reading posts is public — no login/API-key-only restriction
          # beyond whatever BaseController already enforces for the store.
          def index
            page = (params[:page] || 1).to_i
            limit = (params[:limit] || 25).to_i
            offset = (page - 1) * limit

            scope = Spree::Post
                      .where(store: current_store)
                      .where('published_at IS NOT NULL AND published_at <= ?', Time.current)
                      .order(published_at: :desc)

            total_count = scope.count
            posts = scope.limit(limit).offset(offset)

            render json: {
              data: posts.map { |post| serialize_post(post) },
              meta: {
                page: page,
                limit: limit,
                count: total_count,
                pages: (total_count.to_f / limit).ceil
              }
            }
          end

          def show
            post = Spree::Post
                     .where(store: current_store)
                     .where('published_at IS NOT NULL AND published_at <= ?', Time.current)
                     .find_by!(slug: params[:id])

            render json: serialize_post(post, include_content: true)
          rescue ActiveRecord::RecordNotFound
            render json: { error: { code: 'not_found', message: 'Post not found' } }, status: :not_found
          end

          private

          def serialize_post(post, include_content: false)
            data = {
              id: post.id,
              title: post.title,
              slug: post.slug,
              published_at: post.published_at,
              meta_title: post.meta_title,
              meta_description: post.meta_description,
              image_url: post.image.attached? ? Rails.application.routes.url_helpers.url_for(post.image) : nil,
              category: post.respond_to?(:post_category) && post.post_category ? {
                id: post.post_category.id,
                title: post.post_category.title,
                slug: post.post_category.slug
              } : nil
            }
            data[:content] = post.content.to_s if include_content
            data
          end
        end
      end
    end
  end
end
