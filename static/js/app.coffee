React = require 'react'
ReactDOM = require 'react-dom'
async = require 'async'
KefirCollection = require 'kefir-collection'
somata = require './somata-stream'

map = new google.maps.Map document.getElementById('map'), {
    zoom: 8
}

bounds = new google.maps.LatLngBounds()

markers = []

addPoint = (point, cb) ->
    {name, address} = point
    console.log '[addPoint]', name, address
    letter = name[0]
    marker = new google.maps.Marker
        position: point.position
        title: name + ' ' + address
        icon: "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=#{letter}|FE7569"
    markers.push marker
    marker.setMap map
    bounds.extend point.position
    map.fitBounds bounds
    cb()

showPoints = (points) ->
    markers?.map (marker) -> marker.setMap null
    markers = []
    bounds = new google.maps.LatLngBounds()
    async.map points, addPoint, ->
        showCenterPoint()
        showAveragePoint()

showCenterPoint = ->
    center_marker = new google.maps.Marker
        position: bounds.getCenter()
        title: "Centerpoint"
        icon: "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=X|0EF569"
    center_marker.setMap map
    markers.push center_marker

add = (a, b) -> a + b
sum = (l) -> l.reduce(add, 0)
avg = (l) -> sum(l) / l.length

showAveragePoint = ->
    good_markers = markers.filter (marker) ->
        marker.title != 'Centerpoint'
    console.log 'g', good_markers.length
    lats = good_markers.map (m) -> m.position.lat()
    lngs = good_markers.map (m) -> m.position.lng()
    avg_lat = avg lats
    avg_lng = avg lngs
    average_position = new google.maps.LatLng avg_lat, avg_lng
    average_marker = new google.maps.Marker
        position: average_position
        title: "Averagepoint"
        icon: "http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=A|5EC9F5"
    average_marker.setMap map
    markers.push average_marker

points$ = KefirCollection [], id_key: 'name'
points$.onValue showPoints

opoints = [
    {name: 'Sean Robertson', address: '94122'}
    {name: 'Yazan Nahas', address: '94040'}
    {name: 'Yazan Aldehayyat', address: '98114'}
    {name: 'Steven Lam', address: '02155'}
]

points$.plug somata.remote('centerpoint', 'findPoints')

NewPoint = React.createClass
    getInitialState: ->
        name: ''
        address: ''
        errors: {}

    componentDidMount: ->
        @refs.name.focus()

    onChange: (key) -> (e) =>
        value = e.target.value
        update = {}
        update[key] = value
        @setState update

    save: (e) ->
        e.preventDefault()
        {name, address} = @state
        if !name?
            @setState {errors: name: true}
        else if !address?
            @setState {errors: address: true}
        else
            new_point = {name, address}
            somata.remote('centerpoint', 'createPoint', new_point).onValue (created_point) =>
                if !created_point.position
                    @setState {errors: address: true}
                else
                    points$.createItem created_point
                    @setState @getInitialState()
                    @refs.name.focus()

    render: ->
        <form onSubmit=@save>
            <input
                ref='name'
                className={'name' + if @state.errors.name then ' invalid' else ''} 
                value=@state.name
                onChange=@onChange('name') />
            <input
                className={'address' + if @state.errors.address then ' invalid' else ''}
                value=@state.address
                onChange=@onChange('address') />
            <button>Save</button>
        </form>

PointsList = React.createClass
    getInitialState: ->
        points: []

    componentDidMount: ->
        points$.onValue @setPoints

    setPoints: (points) ->
        @setState {points}

    removePoint: (point) -> =>
        somata.remote('centerpoint', 'removePoint', point.name).onValue =>
            points$.removeItem point.name

    render: ->
        <div>
            {@state.points.map (point) =>
                <div className='point'>
                    <span className='name'>{point.name}</span>
                    <span className='address'>{point.address}</span>
                    <a onClick=@removePoint(point) className='delete'>&times;</a>
                </div>
            }
            <NewPoint />
        </div>

ReactDOM.render <PointsList />, document.getElementById 'points-list'
