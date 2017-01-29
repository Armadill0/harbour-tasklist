
//trim objects if they provide a trim() function (e. g. strings), else just the original object
function trimmed(obj) {
    if(obj.trim)
        return obj.trim()
    return obj
}
