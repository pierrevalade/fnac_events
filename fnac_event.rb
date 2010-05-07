# == Schema Information
# Schema version: 20090225173335
#
# Table name: fnac_events
#
#  id              :integer(4)      not null, primary key
#  event_id        :integer(4)      
#  place_id        :integer(4)      
#  title           :string(255)     
#  url             :string(255)     
#  date_valid_from :datetime        
#  date_valid_to   :datetime        
#  price           :decimal(8, 2)   
#  affiliate_url   :string(255)     
#  fnac_id         :string(255)     
#  fnac_name       :string(255)     
#  sub_category    :string(255)     
#  publisher       :string(255)     
#  place_name      :string(255)     
#  place_fnac_name :string(255)     
#  place_lat       :decimal(15, 10) 
#  place_lng       :decimal(15, 10) 
#  place_address   :string(255)     
#  place_city      :string(255)     
#  place_zipcode   :string(255)     
#  place_region    :string(255)     
#  place_country   :string(255)     
#  genre1          :boolean(1)      
#  genre2          :boolean(1)      
#  genre3          :boolean(1)      
#  genre4          :boolean(1)      
#  genre5          :boolean(1)      
#  genre6          :boolean(1)      
#  genre7          :boolean(1)      
#  genre8          :boolean(1)      
#  created_at      :datetime        
#  updated_at      :datetime        
#

class FnacEvent < ActiveRecord::Base
  
  
  
  # Sphinx
  define_index do
    indexes title
    indexes place_name
    indexes publisher
    set_property :field_weights => { :title => 30, :place_name => 5, :publisher => 5 }
    has 'RADIANS(place_lat)', :as => :latitude,  :type => :float
    has 'RADIANS(place_lng)', :as => :longitude,  :type => :float
    set_property :latitude_attr   => "latitude"
    set_property :longitude_attr  => "longitude"
  end
  
  # Validations
  validates_presence_of :title, :fnac_id
  validates_uniqueness_of :fnac_id
  # validates_datetime :date_valid_from, :allow_blank => true
  # validates_datetime :date_valid_to, :allow_blank => true, :after => :date_valid_from
  validates_presence_of :place_name
  validates_presence_of :url
  validate :lat_and_lng_set_to_null_if_zero
  
  ROOT = "http://plateforme.fnacspectacles.com"
  
  def self.url(event_id)
    "#{FnacEvent::ROOT}/place-spectacle/manifestation/xxx-#{event_id}.htm"
  end
  
  private
    def lat_and_lng_set_to_null_if_zero
      if place_lat.to_f == 0.0 || place_lng.to_f == 0.0
        self.place_lat = nil
        self.place_lng = nil
      end
    end
end
