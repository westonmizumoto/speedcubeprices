class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  def thecubicleSearch(searchTerms)
		url = "https://thecubicle.us/advanced_search_result.php?search_in_description=0&keywords="
		delimiter = "+"
		searchTerms.each do |term|
			url += term
			url += delimiter
		end
		page = Nokogiri::HTML(open(url)) 
		numResults = page.css("strong")[3] #Magic number 3
		if numResults == nil then
			return {}, []
		end
		numResults = numResults.text.to_i
		if numResults == 0 then
			return {}, []
		end
		allLinks = (page.css(".productListTable")).css("a")
		links = []
		counter = 0
		for i in 0..numResults - 1
			links.push(allLinks[counter]['href'])
			counter += 3
		end
		results = page.css("td")
		index = 6; 
		counter = 0
		puzzles = Hash.new
		for i in 1..numResults
   			name = results[index].text
   			if results[index + 2].text.include? "$" then #For out of stock stuff
   				index-= 1
   			end
   			price = results[index + 3].text
   			index += 6
   			puzzles[name] = price
		end
		return puzzles,links
	end


	def speedcubeshopSearch(searchTerms)
		#List all results, and then only choose the ones where all search terms appear in the title
		url = "http://speedcubeshop.com/index.php?route=product/search&filter_name="
		delimeter = "%20"
		searchTerms.each do |term|
			url += term
			url += delimeter
		end
		url += "&limit=100"
		page = Nokogiri::HTML(open(url))

		numResults = page.css(".results").text
		numResults = numResults.split(" ")[3].to_i
		if numResults == 0 then
			return {},[]
		end
		results = page.css(".product-list")
		results = results.css("div")


		allLinks = page.css(".product-list").css(".name").css("a")
		puzzles = Hash.new
		links = Array.new
		index = 3
		for i in 1..numResults
			name = results[index].text
			price = results[index + 2].text
			if results[index + 4].text.include? 'Add to Cart' then #Extra div added if there is a rating
				index+= 1
			end
			index += 8
			addThis = true
			searchTerms.each do |term| #Make sure every search term appears in the name
				if !name.downcase.include? term.downcase then
					addThis = false
				end
			end
			if addThis then
				puzzles[name] = price
				links.push(allLinks[i-1]['href'])
			end
		end
		return puzzles, links
	end

	def cubezzSearch(searchTermString)
		url = "http://cubezz.com/search.php?encode="
		searchString = 'a:18:{s:8:"category";s:1:"0";s:7:"display";s:4:"list";s:5:"brand";s:1:"0";s:9:"price_min";s:0:"";s:9:"price_max";s:0:"";s:11:"filter_attr";s:0:"";s:4:"page";s:1:"1";s:4:"sort";s:0:"";s:5:"order";s:0:"";s:8:"keywords";s:'
		searchString += searchTermString.length.to_s
		searchString += ':"'
		searchString += searchTermString
		searchString += '";s:9:"min_price";s:1:"0";s:9:"max_price";s:1:"0";s:6:"action";s:0:"";s:5:"intro";s:0:"";s:10:"goods_type";s:1:"0";s:5:"sc_ds";s:1:"0";s:8:"outstock";s:1:"0";s:18:"search_encode_time";i:1441141819;}'
		searchString = Base64.encode64(searchString)
		url += searchString
		url = URI.encode(url)
		url = URI.parse(url)
		page = Nokogiri::HTML(open(url))

		numResults = page.css(".pagetext")[0].text
		numResults = numResults.split(" ")[1].to_i
		if numResults == 0 then
			return {},[]
		end
		if numResults > 24 then
			##eventually deal with multiple pages
			numResults = 24
		end

		allLinks = page.css(".plist_title").css("a")
		links = Array.new
		for i in 0..numResults-1
			links.push("http://cubezz.com/" + allLinks[i]['href'])
		end

		prices = page.css(".my_shop_price")
		names = page.css(".list_pro_t")
		puzzles = Hash.new
		priceCounter = 1
		for i in 0..numResults-1
			name = names[i].text
			price = "$" + prices[priceCounter].text.split(" ")[1]
			priceCounter += 3
			puzzles[name] = price
		end

		return puzzles,links

	end

	def cubes4speedSearch(searchTerms)
		delimiter = "+"
		url = "http://cubes4speed.com/search?type=product&q="
		searchTerms.each do |term|
			url += term
			url += delimiter
		end
		url = URI.encode(url)
		url = URI.parse(url)
		page = Nokogiri::HTML(open(url))
		names = page.css("h3")  #Why did he do it this way? -___-
		prices = page.css("h4")
		numResults = names.length
		if numResults == 0 then
			return {},[]
		end


		allLinks = page.css(".product-grid").css("a")
		links = Array.new



		puzzles = Hash.new
		for i in 0..numResults - 1
			shouldAdd = true
			searchTerms.each do |term|
				if !names[i].text.downcase.include? term.downcase then
					shouldAdd = false
				end
			end
			if shouldAdd then
				puzzles[names[i].text] = prices[i].text
				links.push("http://cubes4speed.com" + allLinks[i]['href'])
			end
		end
		return puzzles, links
	end
end
