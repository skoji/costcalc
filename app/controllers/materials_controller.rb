class MaterialsController < ApplicationController
  before_action :set_material, only: [:show, :edit, :update, :destroy]
  
  def index
    @materials = Material.all
  end

  def new
    @material = Material.new
  end

  def create
    # 暫定的にuser_id = 1を使用（後で認証実装時に変更）
    @material = Material.new(material_params.merge(user_id: 1))
    
    if @material.save
      redirect_to @material, notice: '材料が作成されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @material.update(material_params)
      redirect_to @material, notice: '材料が更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @material.destroy
    redirect_to materials_path, notice: '材料が削除されました。'
  end

  def show
  end
  
  private
  
  def set_material
    @material = Material.find(params[:id])
  end
  
  def material_params
    params.require(:material).permit(:name, :price)
  end
end
