
MYSQL =
  host : 'perterpon.mysql.rds.aliyuncs.com'
  user : 'girl'
  password : 'pon423904'
  database : 'girl'

exec     = require( 'child_process' ).exec

request  = require 'request'

thunkify = require 'thunkify'

cheerio  = require 'cheerio'

db       = require( './core/db' )()

co       = require 'co'

request  = thunkify request

count    = 1

class Index

  constructor : ->
    db.init { database : MYSQL, log : console }
    db.query = thunkify db.query
    exec     = thunkify exec

  run : co ->
    while true
      @beginCycle()
      yield @sleep 1000

  beginCycle : co ->
    try
      count++
      list = yield exec "curl -d 'sex=f&key=&stc=sex=f&key=&stc=1%3A33%2C2%3A24.24%2C3%3A160.175%2C23%3A1&sn=default&sv=1&p=#{count}&f=select&listStyle=bigPhoto&pri_uid=0&jsversion=v5' http://search.jiayuan.com/v2/search_v2.php"
      [ body ] = list
      resList = JSON.parse body.replace( '##jiayser##', '' ).replace '##jiayser##//', ''
      { userInfo, count } = resList
      data = []
      sql =
        """
        INSERT INTO girl (
          source,
          name,
          age,
          educational,
          portrait_url,
          address,
          high,
          con_id,
          images_url,
          weight,
          zodiac
        )
        VALUES ( :data )
        """
      for item, idx in userInfo
        { realUid:uid } = item
        yield @sleep 200
        detailReqOption =
          url : "http://www.jiayuan.com/#{uid}"
          headers : 
            Host: 'www.jiayuan.com'
            'User-Agent' : 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36'
        detail  = yield request detailReqOption
        [ trash, body ] = detail
        # data.push @parseDetail uid, body
        yield db.query sql, { data : @parseDetail uid, body }
        console.log "insert #{uid} completed!"
    catch e
      console.log e

  getDetail : thunkify ( uid, done ) ->
    reqOption =
      url : "http://www.jiayuan.com/#{uid}"
      headers : 
        Host: 'www.jiayuan.com'
        'User-Agent' : 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36'
    detail = request reqOption, done

  parseDetail : ( uid, body ) ->
    $ = cheerio.load body
    imgs         = $ '.img_absolute'
    images_url   = (
      for img in imgs
        $( img ).attr '_src'
    )
    portrait_url = images_url[ 0 ]
    nameInfo     = $( '.member_info_r' ).find( 'h4' ).text()
    [ name, id ] = nameInfo.split 'ID:'
    [ age, satuation, address ] = $( '.member_name' ).text().split '，'
    address     ?= ''
    address      = address.replace '来自', ''
    high         = $( $( $( '.my_information .details li' )[ 0 ] ).find( 'span' )[ 0 ] ).text().replace( '身高：', '' ).replace '厘米', ''
    educational  = $( $( $( '.my_information .details li' )[ 0 ] ).find( 'span' )[ 0 ] ).text().replace '学历：', ''
    memberinfo   = $ '.member_info_list li'
    educational  = memberinfo.eq( 0 ).find( 'div' ).eq( 1 ).text().trim()
    high         = memberinfo.eq( 1 ).find( 'div' ).eq( 1 ).text().trim()
    weight       = memberinfo.eq( 5 ).find( 'div' ).eq( 1 ).text().trim()
    zodiac       = memberinfo.eq( 8 ).find( 'div' ).eq( 1 ).text().trim()
    [ 'jiayuan', name, age, educational, portrait_url, address, high, uid, JSON.stringify( images_url ), weight, zodiac ]

  sleep : thunkify ( time, done ) ->
    setTimeout done, time

( new Index ).run()

# module.exports =
#   run : ->
#     index = new Index
#     index.run()
