console.log("hello!!")
fetch("https://d3ursguoush4q6.cloudfront.net/api/headers")
    .then(res => {
        console.log(res.body)
    })
    .catch(err => {
        console.error(err)
    })
