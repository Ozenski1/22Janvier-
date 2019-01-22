#######################################################################################################################
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   REQUIRED   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'json'
require "google_drive"
require 'csv'

#######################################################################################################################
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   METHODS   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#

class Townhall
  PAGE_URL = 'http://annuaire-des-mairies.com/val-d-oise.html'
  PAGE_URL2 = 'http://annuaire-des-mairies.com/'

  #On définit la fonction pour récupérer les URLs des différentes villes.


  def get_townhall_urls

     page = Nokogiri::HTML(open(PAGE_URL))
     cities = []
     path_city = page.css('a.lientxt')  # On récupère les données brutes
     path_city.each do |city|
      a = city['href']                  # On récupère le href qui link vers les pages des communes
      a[0] = ''
      cities << a
      end

      return cities
  end

#On définit la fonction pour récupérer les infos.
  def get_townhall_email(urls)

    #On définit les arrays principaux.
    city_mail = []     # Pour les mails
    city_name = []     # Pour les noms
    fusion = []        # Array final qui contiendra les hashs

    #On récupère les infos.
    urls.each do |url|

      page = Nokogiri::HTML(open(PAGE_URL2+url))   # On combine l'url de base et les url de chaque commune.
      emails_path = page.xpath('/html/body/div/main/section[2]/div/table/tbody/tr[4]/td[2]')
      name_path = page.css('small')
      city_name_temp = name_path.text    # On récupère les noms.
      city_name_temp[0..10] = ''         # On enlève le "Commune de".
      city_mail << emails_path.text
      city_name << city_name_temp
    end

    city_name.each_with_index do |name, i|   # On fusionne tous les éléments.

      # On crée une variable pour indiquer les e-mails non renseignés.
      empty_mail = "Not found"

      city_mail[i].length < 1 ? city_mail[i] = empty_mail : nil # Condition pour emails non renseignés
      fusion[i] = { name => city_mail[i] }
    end
    return fusion

  end

####méthode pour initialiser le json
  def save_as_JSON (objet)
    File.open("./db/emails.JSON","w") do |f|
      f.write(objet.to_json)
    end
  end

####méthode pour initialiser la sauvegarde spreadsheet
  def save_as_spreadsheet(objet)
    session = GoogleDrive::Session.from_config("config.json") #définit la session Google Drive à partir de la configuration du fichier config.json
    ws = session.spreadsheet_by_key("1VmrH1HvROJC5Aq1kM_oVO95SVIYrOfB7_oMyXkqicHU").worksheets[0] #définit le Google sheet sur lequel on travaille
    ws[1,1] = "Nom de la ville" #initialise le titre de la colonne 1
    ws[1,2] = "Email" #initialise le titre de la colonne 2
    i=2 #on commence la boucle de remplissage du spreadsheet à partir de la ligne 2
      objet.each do |value| #boucle de remplissage du spreadsheet en fonction des valeurs de l'objet mis en paramètre
          ws[i,1]=value.keys.join # remplit la colonne 1 pour chaque ligne
          ws[i,2]=value.values.join#remplit à la ligne i colonne 2(b) de la valeur
          i=i+1 #incrémentation, remplit chaque ligne à partir de i=2
      end
      ws.save #sauvegarde dans le spreadsheet les éléments de ws
    end

####méthode pour initialiser le CSV

    def save_as_csv (objet)
        CSV.open("./db/emails.csv", "wb") do |csv|
          objet.each do |element|
            csv << [element.keys.join.to_s, element.values.join.to_s]
          end
        end
      end



####méthode perform
  def perform
    save_as_JSON(get_townhall_email(get_townhall_urls))
    save_as_spreadsheet(get_townhall_email(get_townhall_urls))
    save_as_csv(get_townhall_email(get_townhall_urls))
  end

end
#######################################################################################################################
