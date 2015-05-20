harbour-tasklist
================

A small but mighty program to manage your daily tasks.

Pull-Requests
================
Pull-Requests are always welcome. But please respect the following rules to make the life of the collaborators easier. ;-)
- All Pull-Requests have to be sent to the "next" branch!
- Don't use fixed pixel sizes for elements, anchors or anything else in the code.
- Don't remove features (neither small ones) without asking to do so.
- If there's a ticket which has been solved by a commit, please mark it with the default Github referencing possibilities.
- Don't use colored text or UI elements. Please read the SailfishOS Design Giudelines if not already done: https://sailfishos.org/design/

Contact
================
Email: tasklist [at] penguinfriends [dot] org

IRC: #sailfishos - Freenode

Features
================
- multiple task lists
    - set default list which is displayed on application start
    - set the list which is displayed in the cover
    - move tasks between lists (user requested feature)
    - lock/unlock orientation on demand (user requested feature)
- add multiple tasks from the clipboard, devided by new lines (user requested feature)
    - to avoid invalid massive task additions this is done via a remorse action
- cover shows current, it's own or the default task list
    - cover action to add task to list shown in cover
    - cover action to switch between lists (user requested feature)
- task can be marked as done
    - function to delete all done tasks
    - marking of done/open tasks can be inverted (user requested feature)
- orientation can be temporary locked (user requested feature)
- remorse items for all necessary actions (e.x. delete tasks/lists)
    - configurable remorse item times
- multiple languages supported (depending on system language), for more information see below
- app can be started to background, in list view or to default list by setting

Internationalization
================
- current languages: English (default), German, Spanish, Russian, French, Turkish, Czech, Finnish, Swedish, Dutch, Catalan, Italian, Chinese (Mainland), Danish, Lithuanian
- translations are managed via Transifex: https://www.transifex.com/projects/p/tasklist/
    - Feel free to request new languages or complete existing ones there. :-)
    - If you don't want to create a new account there, you can Login via Github, LinkedIn, Google, Facebook or Twitter. I hope this fits all your needs.
    - Every contributor will be mentioned in the About page!

Known Issues
================
see here: https://github.com/Armadill0/harbour-tasklist/issues?q=is%3Aopen+is%3Aissue+label%3Abug

Roadmap for Version 2.0
================
see here: https://github.com/Armadill0/harbour-tasklist/milestones/2.0

Contributors
================
- Manuel Soriano
- Ilja Balonov
- L&eacute;onard Meyer
- Anatoly Shipitsin
- fri
- Jiri Gr&ouml;nroos
- &#304;smail Adnan Sar&#305;er
- &Aring;ke Engelbrektson
- Heimen Stoffels
- Agust&iacute; Clara
- lorenzo facca
- TylerTemp
- Peter Jespersen
- Moo
- Murat Khairulin
