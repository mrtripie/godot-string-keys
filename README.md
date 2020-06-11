# StringKeys for Godot Engine
StringKeys allows you to automatically generate a .csv translation file from strings in your game with a certain prefix.
For example, if you use the default prefix of **"\$\$"** and have the string **"\$\$Hello"** it will add **"\$\$Hello"** as a key and set the english translation to **"Hello"**, and you can add new translations such as **"Hola"** for spanish:

Example translations.csv file:
| key | en | es |
|--|--|--|
| $$Hello | Hello  | Hola |

## SUPPORTED FORMATS:

 - StringKeys can search any text based format that saves strings between "quotation marks" for strings such as:

| File type | Format |
|--|--|
| Godot Text Scene | .tscn |
| Godot Text Resource | .tres |
| Gd Script | .gd |
| C# Script | .cs |

(And most other text based script formats)

- These Godot specific binary formats (only these):

| File type | Format |
|--|--|
| Godot Binary Scene | .scn |
| Godot Binary Resource | .res |
| Godot Visual Script | .vs |

The binary formats take a little longer to search since StringKeys first converts them to a temporary text based file

## TUTORIAL:
#### Basic Setup:
1. Download newest release for your engine version (if you're using Godot 3.2, choose the newest version of 3.2.X)

2. If your project doesn't have an **addons folder (res://addons/)**, create one

3. **Copy the string_keys folder (under addons) and paste it under your project's addons folder**

4. In the top left of Godot go to **Project > Project Settings > Plugins tab**  find the **StringKeys addon**, and set the **Status to Active**

5. There should now be a **StringKeys dock** in the top right. Under it **set the name and path of the Translation File** you want it to generate **(such as res://localization/translations.csv)**

6. Add strings that you want to translate in your project, Dialogue and/or UI. The string should be in the format: 
{prefix}{text}, the prefix is a part of the string that tells StringKeys that this string should be used as a translation key, it should be something that you don't expect will be part of any other keys, the default setting is **"\$\$"**. An example key would be on a button in your UI with the text: **"\$\$New Game"** which will be added as a key and assuming **Text From Key** is turned on, will generate the translation for your native locale as **"New Game".** 

You can also add an **optional category/note before the prefix** which will be **ignored by Text From Key, but will group together all keys with that category (keys are put in alphabetical order).** For example **"UI\$\$New Game"** will also generate the translation **"New Game"** but it will be grouped with all other keys starting with **"UI"** and let the translator know the context of string.

7. Go to StringKeys dock and click **Create Translation File** button. NOTE: Its recommended that only one team member generates the translation file to avoid merge conflicts in version control such as git (and when it trys to automatically solve the conflict, I'm not sure if it will do it correctly)

8. After your csv translation file is generated, Godot will create translation files for each locale in the same folder as your csv file in the format {csv file name}.{locale}.translation (ex: translations.en.translation), go to **project > project settings > Localization side tab, click add and find the .locale.translation files Godot generated and add them.** The translations should work now!

#### Optional/Later Steps:

9. **Hover over the names of the other options for tooltips describing what they do** to set it up the way you want, perhaps using **Modified Only** and maybe **Auto on Save** normally, and occasionally disabling **Modified Only** and using **Remove Unused** to clean up the csv file.

10. You can open up and edit the csv file in **Libre Office Calc** (other spreadsheet programs work too). When the import dialogue shows up, change the **Character Set to "Unicode (UTF-8)"** and have the **only separator option enabled be "Comma"**, click OK, edit and save! If you misspelled your keys, the auto generated first translation will be misspelled, you can use spell check here to fix the translation (column 2) **BUT DON'T FIX THE KEY in Libre Office as Godot will look for the old misspelled one and not find it**. You can also tweak dialogue here quickly (again, only the translation). It's not recommended to manually add keys as StringKeys expects the csv file to be in alphabetical order.

11. You can test other locales in Godot by going to **Project > Project Settings > General tab > Locale side tab** (near the bottom), and **type the locale you want to test in "Test" option**, and erase it when done testing.



## LIKELY POTENTIAL ISSUES
- Merging 2 members versions in version control may cause issues, **its recommended that only one member generates the csv file**
- Back slash \ might be able to confuse what parts of a file are strings (I think this is fixed for all situations)
- Certain situations may cause a problem when using an old .csv file as an input (if keys aren't in alphabetical order for instance)


## KNOWN ISSUES:
- 2 backslashes \\\\ in a row in a translation will be read by Godot as 1, even though the generated file appears to be correct
- Deleting the translation file or manually removing keys will cause StringKeys to miss keys if **Modified Only** is turned on


## POSSIBLE TODOS: (Low priority)
- See if you can make it ensure there are no duplicate keys, even when not in alphabetical order (without complicating things)
- See if you can find a way to deal with modified files when different settings come in to play (such as presets)
- Presets so you can have multiple files scanning different key types (needs modified files to be able to deal with different settings, the above possible todo)
