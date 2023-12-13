//
//  AboutSUIV.swift
//  ScanKit
//
//  Created by Kenneth Schröder on 07.10.21.
//
//UI About界面
import SwiftUI

// https://stackoverflow.com/questions/58341820/isnt-there-an-easy-way-to-pinch-to-zoom-in-an-image-in-swiftui
import PDFKit

struct PhotoDetailView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = PDFDocument()
        guard let page = PDFPage(image: image) else { return view }
        view.document?.insert(page, at: 0)
        view.autoScales = true
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // empty
    }
}

struct AboutSUIV: View { // Help, Details
    @Environment(\.horizontalSizeClass) var sizeClass
    private var mainMenuName = "main_menu"
    private var scanViewImage = "scan_view"
    private var projectsMenuImage = "projects_menu"
    private var detailsMenuImage = "details_menu"
    private var mainMenuTitle = "Main Menu"
    private var scanViewTitle = "Scanning Screen"
    private var projectMenuTitle = "Projects Menu"
    private var detailMenuTitle = "Project Details Screen"
    private var mainMenuDescriptionOne = "The app's home screen allows the user to assign a project name before scanning and to select and deselect the relevant data to be captured for the scan."
    private var mainMenuDescriptionTwo = " In addition, the \"About\" and \"Projects\" pages are accessible. Details about the data format can be found below."
    private var scanViewDescriptionOne = "The scanning screen can be used to start and stop recordings using the green button."
    private var scanViewDescriptionTwo = " Additional controls are provided to change between different perspectives and underlay visualizations."
    private var scanViewDescriptionThree = " The flashlight can be activated using the button on the right to light up dim environments."
    private var scanViewDescriptionFour = " Extended recordings can eventually fill up the main memory. The bar at the bottom of the scanning screen indicates the live main memory utilization."
    private var projectsMenuDescription = "The projects menu displays a list of all scanning projects, which are saved in the Documents folder of your device. The default project names contain data and the time of the recording. Clicking on an item reveals the project details."
    private var detailsMenuDescription = "Project details contain the storage size, scan start and end time, location data (if enabled), and the settings that were selected for the scanning session. From here, you can also upload the entire project to a server via SFTP or open the projects folder in the Files app, which lets you share the data directly via AirDrop or external drives."
    private var formatText = "This zoomable diagram contains our format description. During the scanning procedure, huge amounts of data can accrue. Therefore, saving the data in chunks is necessary to not run out of main memory. We call these chunks FrameCollections. Each FrameCollection JSON file contains references to data frames of up to 10 seconds of a recording. 60 data frames are saved per second, each containing camera metadata, references to a video file with the RGB recording, and file names of the depth and confidence data. ARWorldMap data and QRCode data are not saved per frame but once per FrameCollection. Feel free to contact me for further information."
    //About界面UI
    var body: some View {
        NavigationView {
            VStack {
                List {
                    VStack {
                        HStack {
                            Text("Development").font(.title2).bold()
                            Spacer()
                        }
                        Spacer(minLength: 10)
                        Text("This [MIT-licensed](https://raw.githubusercontent.com/Kenneth-Schroeder/ScanKit/main/LICENSE) app was developed by [Kenneth Schröder](https://www.linkedin.com/in/kenneth-schroeder-dev/).")
                        Spacer(minLength: 10)
                    }
                    VStack {
                        HStack {
                            Text("Usage").font(.title2).bold()
                            Spacer()
                        }
                        if sizeClass == .compact {
                            VStack {
                                HStack {
                                    Text(mainMenuTitle).font(.headline).foregroundColor(Color("Occa"))
                                    Spacer()
                                }
                                Image(mainMenuName).resizable().scaledToFit()
                                Text(mainMenuDescriptionOne + mainMenuDescriptionTwo)
                            }.padding()
                            VStack {
                                HStack {
                                    Text(scanViewTitle).font(.headline).foregroundColor(Color("Occa"))
                                    Spacer()
                                }
                                Image(scanViewImage).resizable().scaledToFit()
                                Text(scanViewDescriptionOne + scanViewDescriptionTwo)
                            }.padding()
                            VStack {
                                HStack {
                                    Text(projectMenuTitle).font(.headline).foregroundColor(Color("Occa"))
                                    Spacer()
                                }
                                Image(projectsMenuImage).resizable().scaledToFit()
                                Text(projectsMenuDescription)
                            }.padding()
                            VStack {
                                HStack {
                                    Text(detailMenuTitle).font(.headline).foregroundColor(Color("Occa"))
                                    Spacer()
                                }
                                Image(detailsMenuImage).resizable().scaledToFit()
                                Text(detailsMenuDescription)
                            }.padding()
                        } else {
                            HStack(alignment: .top) {
                                VStack {
                                    HStack {
                                        Text(mainMenuTitle).font(.headline).foregroundColor(Color("Occa"))
                                        Spacer()
                                    }
                                    Image(mainMenuName).resizable().scaledToFit()
                                    Text(mainMenuDescriptionOne + mainMenuDescriptionTwo)
                                }.padding()
                                VStack {
                                    HStack {
                                        Text(scanViewTitle).font(.headline).foregroundColor(Color("Occa"))
                                        Spacer()
                                    }
                                    Image(scanViewImage).resizable().scaledToFit()
                                    Text(scanViewDescriptionOne + scanViewDescriptionTwo + scanViewDescriptionThree + scanViewDescriptionFour)
                                }.padding()
                            }
                            HStack(alignment: .top) {
                                VStack {
                                    HStack {
                                        Text(projectMenuTitle).font(.headline).foregroundColor(Color("Occa"))
                                        Spacer()
                                    }
                                    Image(projectsMenuImage).resizable().scaledToFit()
                                    Text(projectsMenuDescription)
                                }.padding()
                                VStack {
                                    HStack {
                                        Text(detailMenuTitle).font(.headline).foregroundColor(Color("Occa"))
                                        Spacer()
                                    }
                                    Image(detailsMenuImage).resizable().scaledToFit()
                                    Text(detailsMenuDescription)
                                }.padding()
                            }
                        }
                        VStack {
                            HStack {
                                Text("Output Format").font(.headline).foregroundColor(Color("Occa"))
                                Spacer()
                            }
                            PhotoDetailView(image: UIImage(named: "format_description")!).frame(height: 400).border(Color("Occa"))
                            Text(formatText).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
                        }.padding()
                    }
                }
                Spacer()
            }
            .navigationTitle("About")
        }.navigationViewStyle(StackNavigationViewStyle()).accentColor(Color("Occa"))
        //https://stackoverflow.com/questions/65316497/swiftui-navigationview-navigationbartitle-layoutconstraints-issue/65316745
    }
}

struct AboutSUIV_Previews: PreviewProvider {
    static var previews: some View {
        AboutSUIV()
    }
}
