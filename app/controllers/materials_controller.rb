class MaterialsController < ApplicationController
  before_action :set_material, only: [ :show, :destroy ]

  def index
    @materials = current_user.materials.includes(material_quantities: :unit)
  end

  def new
    @material_form = MaterialForm.new
  end

  def create
    @material_form = MaterialForm.new(material_form_params)

    if @material_form.save(current_user)
      redirect_to materials_path, notice: t("flash.material.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    material = current_user.materials.find(params[:id])
    @material_form = MaterialForm.new(id: material.id)
  end

  def update
    material = current_user.materials.find(params[:id])

    # デバッグ情報
    Rails.logger.debug "=== Material Update Debug ==="
    Rails.logger.debug "Params: #{params.inspect}"
    Rails.logger.debug "material_form_params: #{material_form_params.inspect}"

    @material_form = MaterialForm.new(material_form_params.merge(id: material.id))

    Rails.logger.debug "MaterialForm material_quantities count: #{@material_form.material_quantities.length}"

    if @material_form.save(current_user)
      redirect_to materials_path, notice: t("flash.material.updated")
    else
      Rails.logger.debug "MaterialForm errors: #{@material_form.errors.full_messages}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @material.destroy
    redirect_to materials_path, notice: t("flash.material.destroyed")
  end

  def show
  end

  private

  def set_material
    @material = current_user.materials.find(params[:id])
  end

  def material_form_params
    params.require(:material_form).permit(
      :material_name,
      :material_price,
      material_quantities_attributes: [
        :id,
        :material_count,
        :unit_id,
        :_destroy
      ]
    )
  end
end
