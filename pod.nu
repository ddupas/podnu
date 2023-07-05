#!/usr/bin/env nu

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

# download any images that have been added to national geo photo of the day into the current directory
export def main [] {
    let photos_of_the_day = http get https://www.nationalgeographic.com/photo-of-the-day/
        | rg --only-matching '"https.*?"'
        | rg --only-matching 'http.*?jpg'
        | rg --invert-match '16x9|3x2|2x3|3x4|4x3|_square|2x1'
        | lines
        | uniq
        | sort
        | wrap url
        | upsert filename {|it| $it.url | url parse filename}

    let already_downloaded_images = try { ls *.jpg | get name } catch { [] }

    let photos_to_download = $photos_of_the_day | where {|it|
        not ($it.filename in $already_downloaded_images)
    }

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
def url_parse [] {
    let input = "https://i.natgeofe.com/n/ffe12b1d-8191-44ec-bfb9-298e0dd29825/NationalGeographic_2745739.jpg"
    let expected = "NationalGeographic_2745739.jpg"

    assert equal ($input | url parse filename) $expected

    let input = "http://example.com"
    let expected = ""

    assert equal ($input | url parse filename) $expected
}
