#!/usr/bin/env nu
# pod.nu
# photo of the day nushell
#
# github @ddupas
# github @amtoine

use std log

# parse the name of a URL-based file path
#
# # Example:
# ```nushell
# use std assert
#
# let input = "https://i.natgeofe.com/n/ffe12b1d-8191-44ec-bfb9-298e0dd29825/NationalGeographic_2745739.jpg"
# let expected = "NationalGeographic_2745739.jpg"
#
# assert equal ($input | url parse filename) $expected
# ```
def "url parse filename" [] {  # -> string
    url parse | get path | path parse | update parent "" | path join
}

def "bing url parse filename" [] {  # -> string
    url parse | get params.id
}

# download any images that have been added to national geo photo of the day into the current directory
export def main [] {
    let national_geo_pod = (
        http get https://www.nationalgeographic.com/photo-of-the-day/
        | rg --only-matching '"https.*?"'
        | rg --only-matching 'http.*?jpg'
        | rg --invert-match '16x9|3x2|2x3|3x4|4x3|_square|2x1'
        | lines
        | uniq
        | sort
        | wrap url
        | upsert filename {|it| $it.url | url parse filename}
    )

    let bing_pod = (
        [ $"http://bing.com(
        http get https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US
        | get images.url.0
    )" ]
        | wrap url
        | upsert filename {|it| $it.url | bing url parse filename}
    )

    let all_pod = (
        $national_geo_pod
        | append $bing_pod
    )

    let already_downloaded_images = try { ls *.jpg | get name } catch { [] }

    let photos_to_download = (
        $all_pod | where {|it|
            not ($it.filename in $already_downloaded_images)
        }
    )

    if ($photos_to_download | is-empty) {
        log warning "you have already downloaded all the images of the day!"
        return ()
    }

    $photos_to_download | each {|photo|
        log info $"downloading ($photo.url)"
        http get $photo.url | save --progress $photo.filename
    }

    ()
}

use std assert

#[test]
export def url_parse [] {
    let input = "https://i.natgeofe.com/n/ffe12b1d-8191-44ec-bfb9-298e0dd29825/NationalGeographic_2745739.jpg"
    let expected = "NationalGeographic_2745739.jpg"
    assert equal ($input | url parse filename) $expected
}

export def bing_url_parse [] {
    let input = "http://bing.com/th?id=OHR.CorfuBeach_EN-US1955770867_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp"
    let expected = "OHR.CorfuBeach_EN-US1955770867_1920x1080.jpg"
    assert equal ($input | bing_url parse filename) $expected
}
