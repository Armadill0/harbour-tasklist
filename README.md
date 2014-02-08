harbour-tasklist
================

A small but mighty program to manage your daily tasks.

Features
================
- multiple task lists
    - set default list which is displayed on application start
    - set the list which is displayed in the cover
    - move tasks between lists (user requested feature)
    - lock/unlock orientation on demand (user requested feature)
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

Internationalization
================
- current languages: English (default), German
- new languages tutorial:
    - copy the harbour-tasklist_plain.ts to harbour-tasklist_[your_country_code].ts (e.x. harbour-tasklist_fr_FR.ts)
    - start QT Linguist (part of the Qt SDK)
    - import the harbour-tasklist_[your_country_code].ts file
    - translate all entries and save the file
    - export the library to [your_country_code].qm and send both files to me via mail

Known Bugs
================

Roadmap for Version 1.0
================
- settings
    - time and date display options (there are problems to read the correct local time strings)
- duedate (no API available atm)
    - task alarms
    - dispatch calendar item

Roadmap for Version 2.0
================
- online accounting
- share lists
- csv import/export
