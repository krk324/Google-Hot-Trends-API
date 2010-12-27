require 'hpricot'
require 'rest-open-uri'

class HottrendsController < ApplicationController
  
  # GET api/hottrends/2009-8-16/(5) (:date)(:limit)
  # GET api/hottrends/2009-8-16.xml (:date)(:limit)
  def api_day
    date = params[:date].to_date
    
    create_hot_trends_if_not_in_db_and_final_version(date)
    
    @hottrends = Hottrend.where(:date => date).order(:num).limit(params[:limit] ||= "20")
    
    respond_to do |format|
      format.html # api_day.html.erb
      format.xml  { render :xml => @hottrends }
      format.json  { render :json => @hottrends }
      format.text { render :text => render_txt(@hottrends, date) }
    end
  end

  # GET api/hottrends/2009-8-16/2009-8-24/(5) (:start_date/:end_date)(:limit)
  # GET api/hottrends/2009-8-16/2009-8-24.xml (:start_date/:end_date)(:limit)
  def api_period
    @start_date = params[:start_date].to_date
    @end_date = params[:end_date].to_date

    create_hot_trends_if_not_in_db_and_final_version_by_period(@start_date, @end_date)
    
    @hottrends = []
    date = @start_date
    while date <= @end_date
      @hottrends += Hottrend.where(:date => date).order(:num).limit(params[:limit] ||= "20")
      date = date.+(1)
    end
    
    respond_to do |format|
      format.html # api_period.html.erb
      format.xml  { render :xml => @hottrends }
      format.json  { render :json => @hottrends }
      format.text { render :text => render_txt(@hottrends, @start_date, @end_date ) }
    end
  end

  # GET /hottrends
  # GET /hottrends.xml
  def index
    @hottrends = Hottrend.all
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @hottrends }
    end
  end
  
  # GET /hottrends/1
  # GET /hottrends/1.xml
  def show
    @hottrend = Hottrend.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @hottrend }
    end
  end

  # GET /hottrends/new
  # GET /hottrends/new.xml
  def new
    @hottrend = Hottrend.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @hottrend }
    end
  end

  # GET /hottrends/1/edit
  def edit
    @hottrend = Hottrend.find(params[:id])
  end

  # POST /hottrends
  # POST /hottrends.xml
  def create
    @hottrend = Hottrend.new(params[:hottrend])

    respond_to do |format|
      if @hottrend.save
        format.html { redirect_to(@hottrend, :notice => 'Hottrend was successfully created.') }
        format.xml  { render :xml => @hottrend, :status => :created, :location => @hottrend }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @hottrend.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /hottrends/1
  # PUT /hottrends/1.xml
  def update
    @hottrend = Hottrend.find(params[:id])

    respond_to do |format|
      if @hottrend.update_attributes(params[:hottrend])
        format.html { redirect_to(@hottrend, :notice => 'Hottrend was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @hottrend.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /hottrends/1
  # DELETE /hottrends/1.xml
  def destroy
    @hottrend = Hottrend.find(params[:id])
    @hottrend.destroy

    respond_to do |format|
      format.html { redirect_to(hottrends_url) }
      format.xml  { head :ok }
    end
  end

  def create_hot_trends_if_not_in_db_and_final_version_by_period(start_date, end_date)
    while start_date <= end_date
      create_hot_trends_if_not_in_db_and_final_version(start_date)
      start_date = start_date.+(1)
    end
  end
  
  def create_hot_trends_if_not_in_db_and_final_version(date)
    hottrend = Hottrend.where(:date => date)
    if hottrend.empty?
      create_hot_trends_in_db(date)
    elsif (hottrend[0].updated_at <= hottrend[0].date)
      destroy_hot_trends_in_db(date)
      create_hot_trends_in_db(date)
    end
  end

  def destroy_hot_trends_in_db(date)
    date = date.to_s
    hts = Hottrend.where(:date => date.to_date)
    hts.each do |ht|
      ht.destroy
    end
  end

  def create_hot_trends_in_db(date)
    date = date.to_s
    hdrs = {"User-Agent"=>"Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1", "Accept-Charset"=>"utf-8", "Accept"=>"text/html"}
    my_html = ""
    url = "http://www.google.com/trends/hottrends?date="+date
    page = open(url, hdrs).each {|s| my_html << s}
    @web_doc =  Hpricot(my_html)

    @i = 0
    (@web_doc/"td.hotColumn").search("a").each do |e|
      Hottrend.create(:date => date.to_date, :text => e.inner_html, :num => @i, :culture => "en_US")
      @i += 1
    end
  end

  def render_txt hottrends, date, end_date = nil
    end_date ||= date
    text = ""
    
    while date <= end_date
      text += "#{date.strftime("%B %d, %Y")}\n" #October 31, 2010
      
      i = 1
      hottrends.each do |h|
        if h.date == date
          text += i.to_s+". "
          text += h.text+"\n"
          i+=1
        end
      end
      
      text += "\n"
      
      date = date.+(1)
    end

    return text
  end

end
