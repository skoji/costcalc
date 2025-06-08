class ProductsController < ApplicationController
  before_action :set_product, only: [ :show, :destroy ]

  def index
    @products = current_user.products.includes(:product_ingredients, :user)
  end

  def new
    @product_form = ProductForm.new
  end

  def create
    @product_form = ProductForm.new(product_form_params)
    begin
      @product_form.persist!(current_user)
      product = @product_form.product
      redirect_to product_path(product), notice: "Product was successfully created."
    rescue => e
      flash.now[:error] = "作成に失敗しました: #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @product_form = ProductForm.new(id: params[:id])
  end

  def update
    @product_form = ProductForm.new(product_form_params)
    begin
      @product_form.persist!(current_user)
      redirect_to product_path(@product_form.product), notice: "Product was successfully updated."
    rescue => e
      flash.now[:error] = "更新に失敗しました: #{e.message}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Product was successfully destroyed."
  end

  def show
  end

  private

  def set_product
    @product = current_user.products.find(params[:id])
  end

  def product_form_params
    params.require(:product_form).permit(
      :id,
      :product_name,
      :product_count,
      product_ingredients_attributes: [
        :ingredient_count,
        :id,
        :material_id,
        :unit_id,
        :delete
      ]
    )
  end
end
