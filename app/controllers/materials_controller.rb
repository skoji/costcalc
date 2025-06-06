class MaterialsController < ApplicationController
  before_action :set_material, only: [:show, :edit, :update, :destroy]
  
  def index
    @materials = current_user.materials
  end

  def new
    @material = current_user.materials.build
  end

  def create
    @material = current_user.materials.build(material_params)
    
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
    @material = current_user.materials.find(params[:id])
  end
  
  def material_params
    params.require(:material).permit(:name, :price)
  end
end
