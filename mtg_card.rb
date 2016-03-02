#!/usr/bin/env ruby
require 'sinatra'
require 'sinatra/json'
require 'net/http'
require 'json'

def make_response(text, attachments = [], response_type = 'in_channel')
  {
    text: text,
    attachments: attachments,
    username: 'MTG Bot',
    icon_url: 'http://seeklogo.com/images/M\
               /magic-the-gathering-logo-E672A43B2E-seeklogo.com.gif',
    icon_emoji: '',
    response_type: response_type
  }
end

def card_info(text)
  uri = URI.parse('https://api.deckbrew.com/mtg/cards')
  uri.query = URI.encode_www_form(name: text)
  data = JSON.parse(Net::HTTP.get(uri))
  card = data.find { |x| x['name'].casecmp(text.downcase).zero? }
  card = data.first if card.nil?

  if card.nil?
    return make_response("Could not match `#{text}` to any cards.",
                         'ephemeral')
  end

  cost = {
    title: 'Cost',
    value: card['cost'],
    short: true
  } unless card['cost'].empty?

  type_text = ''
  card['supertypes'].each do |t|
    type_text << "#{t.capitalize} "
  end unless card['supertypes'].nil?

  card['types'].each do |t|
    type_text << "#{t.capitalize} "
  end unless card['types'].nil?

  type_text << '- ' unless card['subtypes'].nil?

  card['subtypes'].each do |t|
    type_text << "#{t.capitalize} "
  end unless card['subtypes'].nil?

  type = {
    title: 'Type',
    value: type_text.strip,
    short: true
  }

  card_text = nil
  card_text = {
    title: 'Card Text',
    value: card['text'],
    short: false
  } unless card['text'].empty?

  p_t = nil
  p_t = {
    title: 'P/T',
    value: "#{card['power']}/#{card['toughness']}",
    short: true
  } unless card['power'].nil? || card['toughness'].nil?

  loyalty = nil
  loyalty = {
    title: 'Loyalty',
    value: card['loyalty'],
    short: true
  } unless card['loyalty'].nil?

  rarity = {
    title: 'Rarity',
    value: card['editions'].last['rarity'].capitalize,
    short: true
  }

  fields = []
  fields << cost
  fields << type
  fields << card_text
  fields << p_t unless p_t.nil?
  fields << loyalty unless loyalty.nil?
  fields << rarity

  attachments = [{
    title: card['name'],
    fields: fields,
    image_url: card['editions'].last['image_url']
  }]

  make_response('', attachments)
end

def combo_info(cards)
  attachments = []
  cards.each do |card_name|
    card_name.strip!
    uri = URI.parse('https://api.deckbrew.com/mtg/cards')
    uri.query = URI.encode_www_form(name: card_name)
    data = JSON.parse(Net::HTTP.get(uri))
    card = data.first

    if card.nil?
      return make_response("Could not match `#{card_name}` to any cards.",
                           'ephemeral')
    end

    attachments << {
      title: card['name'],
      image_url: card['editions'].last['image_url']
    }
  end

  make_response('Combo', attachments)
end

post '/' do
  cards = params['text'].split '+'
  if cards.length == 1
    json card_info(cards.first)
  else
    json combo_info(cards)
  end
end