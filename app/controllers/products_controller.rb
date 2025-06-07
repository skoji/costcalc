class ProductsController < ApplicationController
  before_action :set_product, only: [ :show, :destroy ]

  def index
    @products = current_user.products.includes(:product_ingredients, :user)
  end

  def new
    @product_form = ProductForm.new
  end

  def create
    if params[:commit] == "材料追加"
      @product_form = ProductForm.new(product_form_params)
      @product_form.add_product_ingredient(ProductIngredientForm.new)
      render :new, status: :unprocessable_entity
    else
      @product_form = ProductForm.new(product_form_params)
      begin
        @product_form.persist!(current_user)
        product = @product_form.product
        redirect_to product_path(product), notice: "製品が作成されました。"
      rescue => e
        flash.now[:error] = "作成に失敗しました: #{e.message}"
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
    @product_form = ProductForm.new(id: params[:id])
  end

  def update
    if params[:commit] == "材料追加"
      @product_form = ProductForm.new(product_form_params)
      @product_form.add_product_ingredient(ProductIngredientForm.new)
      render :edit, status: :unprocessable_entity
    else
      @product_form = ProductForm.new(product_form_params)
      begin
        @product_form.persist!(current_user)
        redirect_to product_path(@product_form.product), notice: "製品が更新されました。"
      rescue => e
        flash.now[:error] = "更新に失敗しました: #{e.message}"
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "製品が削除されました。"
  end

  def show
  end

  private

  def set_product
    @product = current_user.products.find(params[:id])
  end

  def product_form_params
    # legacy版と同じパラメータ処理
    if params[:product_form]
      params[:product_form].each do |k, v|
        params[k] = v
      end
    end

    params.permit(
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
